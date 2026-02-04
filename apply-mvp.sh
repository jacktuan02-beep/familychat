#!/usr/bin/env bash
set -e

echo "==> Installing deps..."
npx expo install firebase expo-firebase-recaptcha expo-auth-session expo-crypto expo-file-system expo-image-picker expo-contacts
npm i zod

echo "==> Writing source files..."

mkdir -p src/lib src/features src/features/chat src/features/friends src/features/drive src/i18n
mkdir -p app/'(auth)' app/'(tabs)' app/'(tabs)'/chats app/'(tabs)'/friends app/'(tabs)'/groups

cat > src/lib/firebase.ts <<'TS'
import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY!,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN!,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID!,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET!,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID!,
};

const app = getApps().length ? getApps()[0] : initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
TS

cat > src/i18n/t.ts <<'TS'
export type Lang = "vi" | "en";
export const getLang = (): Lang => (process.env.EXPO_PUBLIC_LANG === "en" ? "en" : "vi");

const vi = {
  loginTitle: "Đăng nhập bằng số điện thoại",
  phone: "Số điện thoại",
  sendOtp: "Gửi mã",
  otp: "Mã OTP",
  verify: "Xác nhận",
  chats: "Chat",
  friends: "Bạn bè",
  groups: "Nhóm",
};

const en = {
  loginTitle: "Sign in with phone",
  phone: "Phone number",
  sendOtp: "Send code",
  otp: "OTP code",
  verify: "Verify",
  chats: "Chats",
  friends: "Friends",
  groups: "Groups",
};

export const t = (k: keyof typeof vi) => (getLang() === "en" ? en[k] : vi[k]);
TS

cat > src/features/friends/api.ts <<'TS'
import { db } from "../../lib/firebase";
import { doc, getDoc, setDoc, query, where, collection, getDocs } from "firebase/firestore";

export async function upsertProfile(uid: string, phone: string) {
  const ref = doc(db, "users", uid);
  await setDoc(ref, { uid, phone, createdAt: Date.now() }, { merge: true });
}

export async function findUserByPhone(phone: string) {
  const q = query(collection(db, "users"), where("phone", "==", phone));
  const snap = await getDocs(q);
  if (snap.empty) return null;
  const d = snap.docs[0].data() as any;
  return { uid: d.uid as string, phone: d.phone as string };
}

export async function addFriend(myUid: string, otherUid: string) {
  await setDoc(doc(db, "friends", `${myUid}_${otherUid}`), { a: myUid, b: otherUid, createdAt: Date.now() }, { merge: true });
  await setDoc(doc(db, "friends", `${otherUid}_${myUid}`), { a: otherUid, b: myUid, createdAt: Date.now() }, { merge: true });
}

export async function listFriends(myUid: string) {
  const q = query(collection(db, "friends"), where("a", "==", myUid));
  const snap = await getDocs(q);
  return snap.docs.map(d => (d.data() as any).b as string);
}

export async function getUser(uid: string) {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);
  return snap.exists() ? (snap.data() as any) : null;
}
TS

cat > src/features/chat/api.ts <<'TS'
import { db } from "../../lib/firebase";
import { collection, doc, getDoc, setDoc, addDoc, query, where, orderBy, limit, onSnapshot } from "firebase/firestore";

function dmId(a: string, b: string) {
  return [a, b].sort().join("_");
}

export async function ensureDM(a: string, b: string) {
  const id = dmId(a, b);
  const ref = doc(db, "chats", id);
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    await setDoc(ref, { id, kind: "dm", memberUids: [a, b], createdAt: Date.now(), updatedAt: Date.now() });
  }
  return id;
}

export async function sendText(chatId: string, fromUid: string, text: string) {
  await addDoc(collection(db, "chats", chatId, "messages"), { chatId, fromUid, type: "text", text, createdAt: Date.now() });
  await setDoc(doc(db, "chats", chatId), { updatedAt: Date.now(), lastMessage: { text, at: Date.now() } }, { merge: true });
}

export function subscribeMessages(chatId: string, cb: (msgs: any[]) => void) {
  const q = query(collection(db, "chats", chatId, "messages"), orderBy("createdAt", "asc"), limit(200));
  return onSnapshot(q, (snap) => cb(snap.docs.map(d => ({ id: d.id, ...d.data() }))));
}

export function subscribeMyChats(myUid: string, cb: (rows: any[]) => void) {
  const q = query(collection(db, "chats"), where("memberUids", "array-contains", myUid), orderBy("updatedAt", "desc"), limit(50));
  return onSnapshot(q, (snap) => cb(snap.docs.map(d => d.data() as any)));
}
TS

cat > app/_layout.tsx <<'TSX'
import { Stack } from "expo-router";
export default function RootLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(auth)/login" />
      <Stack.Screen name="(tabs)" />
    </Stack>
  );
}
TSX

cat > "app/(auth)/login.tsx" <<'TSX'
import React, { useState } from "react";
import { View, Text, TextInput, Pressable, Alert } from "react-native";
import { FirebaseRecaptchaVerifierModal } from "expo-firebase-recaptcha";
import { PhoneAuthProvider, signInWithCredential, signInWithPhoneNumber } from "firebase/auth";
import { auth } from "../../src/lib/firebase";
import { router } from "expo-router";
import { upsertProfile } from "../../src/features/friends/api";
import { t } from "../../src/i18n/t";

export default function Login() {
  const recaptchaRef = React.useRef<FirebaseRecaptchaVerifierModal>(null);
  const [phone, setPhone] = useState("");
  const [verificationId, setVerificationId] = useState<string | null>(null);
  const [code, setCode] = useState("");

  async function send() {
    try {
      const full = phone.startsWith("+") ? phone : `+84${phone.replace(/^0/, "")}`;
      const confirmation = await signInWithPhoneNumber(auth, full, recaptchaRef.current as any);
      setVerificationId(confirmation.verificationId);
      Alert.alert("OK", "Đã gửi OTP");
    } catch (e: any) {
      Alert.alert("Lỗi", e?.message ?? String(e));
    }
  }

  async function verify() {
    try {
      if (!verificationId) return;
      const credential = PhoneAuthProvider.credential(verificationId, code);
      const res = await signInWithCredential(auth, credential);
      const p = phone.startsWith("+") ? phone : `+84${phone.replace(/^0/, "")}`;
      await upsertProfile(res.user.uid, p);
      router.replace("/(tabs)");
    } catch (e: any) {
      Alert.alert("Lỗi", e?.message ?? String(e));
    }
  }

  return (
    <View style={{ flex: 1, padding: 20, justifyContent: "center", gap: 12 }}>
      <FirebaseRecaptchaVerifierModal
        ref={recaptchaRef}
        firebaseConfig={{
          apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY!,
          authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN!,
          projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID!,
          storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET!,
          messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
          appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID!,
        }}
        attemptInvisibleVerification
      />

      <Text style={{ fontSize: 22, fontWeight: "700" }}>{t("loginTitle")}</Text>

      <TextInput
        placeholder={t("phone")}
        value={phone}
        onChangeText={setPhone}
        keyboardType="phone-pad"
        style={{ borderWidth: 1, borderColor: "#ccc", borderRadius: 10, padding: 12 }}
      />

      {!verificationId ? (
        <Pressable onPress={send} style={{ backgroundColor: "black", padding: 12, borderRadius: 10 }}>
          <Text style={{ color: "white", textAlign: "center", fontWeight: "700" }}>{t("sendOtp")}</Text>
        </Pressable>
      ) : (
        <>
          <TextInput
            placeholder={t("otp")}
            value={code}
            onChangeText={setCode}
            keyboardType="number-pad"
            style={{ borderWidth: 1, borderColor: "#ccc", borderRadius: 10, padding: 12 }}
          />
          <Pressable onPress={verify} style={{ backgroundColor: "black", padding: 12, borderRadius: 10 }}>
            <Text style={{ color: "white", textAlign: "center", fontWeight: "700" }}>{t("verify")}</Text>
          </Pressable>
        </>
      )}
    </View>
  );
}
TSX

cat > "app/(tabs)/_layout.tsx" <<'TSX'
import { Tabs } from "expo-router";
import { t } from "../../src/i18n/t";
export default function TabsLayout() {
  return (
    <Tabs screenOptions={{ headerShown: true }}>
      <Tabs.Screen name="chats" options={{ title: t("chats") }} />
      <Tabs.Screen name="friends" options={{ title: t("friends") }} />
      <Tabs.Screen name="groups" options={{ title: t("groups") }} />
    </Tabs>
  );
}
TSX

cat > "app/(tabs)/friends/index.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { View, Text, TextInput, Pressable, Alert, FlatList } from "react-native";
import { auth } from "../../../src/lib/firebase";
import { addFriend, findUserByPhone, getUser, listFriends } from "../../../src/features/friends/api";
import { ensureDM } from "../../../src/features/chat/api";
import { router } from "expo-router";

export default function Friends() {
  const myUid = auth.currentUser?.uid!;
  const [phone, setPhone] = useState("");
  const [friends, setFriends] = useState<any[]>([]);

  async function refresh() {
    const ids = await listFriends(myUid);
    const rows = await Promise.all(ids.map(getUser));
    setFriends(rows.filter(Boolean));
  }

  useEffect(() => { if (myUid) refresh(); }, [myUid]);

  async function onAdd() {
    try {
      const p = phone.trim();
      if (!p) return;
      const full = p.startsWith("+") ? p : `+84${p.replace(/^0/, "")}`;
      const u = await findUserByPhone(full);
      if (!u) return Alert.alert("Không tìm thấy", "Người này chưa đăng ký app");
      if (u.uid === myUid) return Alert.alert("Lỗi", "Không thể tự kết bạn");
      await addFriend(myUid, u.uid);
      setPhone("");
      await refresh();
      Alert.alert("OK", "Đã kết bạn");
    } catch (e: any) {
      Alert.alert("Lỗi", e?.message ?? String(e));
    }
  }

  async function onChat(otherUid: string) {
    const chatId = await ensureDM(myUid, otherUid);
    router.push({ pathname: "/(tabs)/chats/thread", params: { chatId } });
  }

  return (
    <View style={{ flex: 1, padding: 12, gap: 10 }}>
      <Text style={{ fontSize: 18, fontWeight: "800" }}>Kết bạn</Text>
      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput value={phone} onChangeText={setPhone} placeholder="Nhập số điện thoại" style={{ flex: 1, borderWidth: 1, borderColor: "#ccc", borderRadius: 10, paddingHorizontal: 12 }} />
        <Pressable onPress={onAdd} style={{ backgroundColor: "black", paddingHorizontal: 14, justifyContent: "center", borderRadius: 10 }}>
          <Text style={{ color: "white", fontWeight: "700" }}>+</Text>
        </Pressable>
      </View>

      <Text style={{ fontSize: 16, fontWeight: "800", marginTop: 8 }}>Danh sách bạn</Text>
      <FlatList
        data={friends}
        keyExtractor={(it) => it.uid}
        renderItem={({ item }) => (
          <Pressable onPress={() => onChat(item.uid)} style={{ padding: 12, borderWidth: 1, borderColor: "#eee", borderRadius: 12, marginTop: 8 }}>
            <Text style={{ fontWeight: "700" }}>{item.phone}</Text>
            <Text style={{ color: "#555" }}>Bấm để chat</Text>
          </Pressable>
        )}
      />
    </View>
  );
}
TSX

cat > "app/(tabs)/chats/index.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { View, Text, Pressable, FlatList } from "react-native";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "../../../src/lib/firebase";
import { router } from "expo-router";
import { subscribeMyChats } from "../../../src/features/chat/api";

export default function ChatsHome() {
  const [uid, setUid] = useState<string | null>(auth.currentUser?.uid ?? null);
  const [rows, setRows] = useState<any[]>([]);

  useEffect(() => onAuthStateChanged(auth, u => setUid(u?.uid ?? null)), []);
  useEffect(() => {
    if (!uid) return;
    const unsub = subscribeMyChats(uid, setRows);
    return () => unsub();
  }, [uid]);

  if (!uid) {
    return (
      <View style={{ flex: 1, padding: 16, justifyContent: "center" }}>
        <Pressable onPress={() => router.replace("/(auth)/login")} style={{ backgroundColor: "black", padding: 12, borderRadius: 10 }}>
          <Text style={{ color: "white", textAlign: "center", fontWeight: "700" }}>Đăng nhập</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <View style={{ flex: 1 }}>
      <FlatList
        data={rows}
        keyExtractor={(it) => it.id}
        renderItem={({ item }) => (
          <Pressable onPress={() => router.push({ pathname: "/(tabs)/chats/thread", params: { chatId: item.id } })} style={{ padding: 14, borderBottomWidth: 1, borderColor: "#eee" }}>
            <Text style={{ fontWeight: "700" }}>{item.kind === "group" ? (item.title ?? "Nhóm") : "Chat"}</Text>
            <Text numberOfLines={1} style={{ color: "#555" }}>{item.lastMessage?.text ?? ""}</Text>
          </Pressable>
        )}
      />
    </View>
  );
}
TSX

cat > "app/(tabs)/chats/thread.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { View, Text, TextInput, Pressable, FlatList } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { auth } from "../../../src/lib/firebase";
import { subscribeMessages, sendText } from "../../../src/features/chat/api";

export default function Thread() {
  const { chatId } = useLocalSearchParams<{ chatId: string }>();
  const myUid = auth.currentUser?.uid!;
  const [msgs, setMsgs] = useState<any[]>([]);
  const [text, setText] = useState("");

  useEffect(() => {
    if (!chatId) return;
    const unsub = subscribeMessages(String(chatId), setMsgs);
    return () => unsub();
  }, [chatId]);

  async function onSend() {
    const v = text.trim();
    if (!v) return;
    setText("");
    await sendText(String(chatId), myUid, v);
  }

  return (
    <View style={{ flex: 1 }}>
      <FlatList
        data={msgs}
        keyExtractor={(it) => it.id}
        contentContainerStyle={{ padding: 12, gap: 8 }}
        renderItem={({ item }) => (
          <View
            style={{
              alignSelf: item.fromUid === myUid ? "flex-end" : "flex-start",
              maxWidth: "85%",
              padding: 10,
              borderRadius: 12,
              backgroundColor: item.fromUid === myUid ? "#d1f7c4" : "#eee",
            }}
          >
            <Text>{item.text}</Text>
          </View>
        )}
      />

      <View style={{ flexDirection: "row", gap: 8, padding: 10, borderTopWidth: 1, borderColor: "#eee" }}>
        <TextInput value={text} onChangeText={setText} placeholder="Nhập tin nhắn" style={{ flex: 1, borderWidth: 1, borderColor: "#ccc", borderRadius: 10, paddingHorizontal: 12 }} />
        <Pressable onPress={onSend} style={{ paddingHorizontal: 16, paddingVertical: 10, borderRadius: 10, backgroundColor: "black" }}>
          <Text style={{ color: "white", fontWeight: "700" }}>Gửi</Text>
        </Pressable>
      </View>
    </View>
  );
}
TSX

cat > "app/(tabs)/groups/index.tsx" <<'TSX'
import React from "react";
import { View, Text } from "react-native";
export default function Groups() {
  return (
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 16 }}>
      <Text style={{ fontSize: 16, fontWeight: "700" }}>
        Nhóm (MVP): sẽ thêm tạo nhóm + mời bạn bè ở bước kế tiếp.
      </Text>
    </View>
  );
}
TSX

echo "✅ MVP files written."
echo "Run: npx expo start -c"
