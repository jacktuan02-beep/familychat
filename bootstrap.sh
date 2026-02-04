#!/usr/bin/env bash
set -e

echo "==> Creating Expo Router + Firebase chat skeleton..."

# Clean workspace (optional). Comment out if you don't want wipe.
rm -rf app src package.json app.json tsconfig.json .env .gitignore

mkdir -p app/chat src

cat > package.json <<'JSON'
{
  "name": "familychat",
  "version": "1.0.0",
  "main": "expo-router/entry",
  "private": true,
  "scripts": {
    "start": "expo start --tunnel",
    "web": "expo start --web"
  },
  "dependencies": {
    "expo": "^52.0.0",
    "expo-router": "^4.0.0",
    "expo-status-bar": "~2.0.0",
    "react": "18.3.1",
    "react-native": "0.76.5",
    "react-native-gesture-handler": "~2.20.2",
    "react-native-safe-area-context": "4.12.0",
    "react-native-screens": "~4.4.0",
    "firebase": "^10.14.1"
  }
}
JSON

cat > app.json <<'JSON'
{
  "expo": {
    "name": "FamilyChat",
    "slug": "familychat",
    "scheme": "familychat",
    "version": "1.0.0",
    "platforms": ["ios", "android", "web"],
    "web": { "bundler": "metro" }
  }
}
JSON

cat > tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "target": "ES2020",
    "moduleResolution": "bundler",
    "strict": true,
    "baseUrl": "."
  }
}
JSON

cat > .gitignore <<'TXT'
node_modules
.env
.expo
dist
TXT

cat > app/_layout.tsx <<'TSX'
import { Stack } from "expo-router";
import "react-native-gesture-handler";

export default function RootLayout() {
  return (
    <Stack screenOptions={{ headerShown: true }}>
      <Stack.Screen name="index" options={{ title: "FamilyChat" }} />
      <Stack.Screen name="login" options={{ title: "Đăng nhập" }} />
      <Stack.Screen name="home" options={{ title: "Trang chính" }} />
      <Stack.Screen name="chat/[id]" options={{ title: "Chat" }} />
    </Stack>
  );
}
TSX

cat > app/index.tsx <<'TSX'
import { Link } from "expo-router";
import { View, Text, Pressable } from "react-native";

export default function Index() {
  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24, gap: 12 }}>
      <Text style={{ fontSize: 26, fontWeight: "800" }}>FamilyChat</Text>
      <Text style={{ opacity: 0.7 }}>
        Online 100% • Code on GitHub • Android/iOS/Web
      </Text>

      <Link href="/login" asChild>
        <Pressable style={{ padding: 14, borderRadius: 12, backgroundColor: "#111" }}>
          <Text style={{ color: "#fff", textAlign: "center", fontWeight: "700" }}>
            Bắt đầu
          </Text>
        </Pressable>
      </Link>
    </View>
  );
}
TSX

cat > app/login.tsx <<'TSX'
import { router } from "expo-router";
import { useState } from "react";
import { View, Text, TextInput, Pressable } from "react-native";
import { upsertUserByPhone } from "../src/userRepo";

export default function Login() {
  const [phone, setPhone] = useState("");

  async function onContinue() {
    const p = phone.trim();
    if (!p) return;
    // DEMO LOGIN: tạo user theo SĐT để chạy ngay.
    // Bước tiếp theo mình sẽ nâng lên OTP thật giống WhatsApp.
    await upsertUserByPhone(p);
    router.replace("/home");
  }

  return (
    <View style={{ flex: 1, padding: 24, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "800" }}>Nhập số điện thoại</Text>
      <TextInput
        value={phone}
        onChangeText={setPhone}
        placeholder="VD: +84901234567"
        style={{ borderWidth: 1, borderRadius: 12, padding: 12 }}
        autoCapitalize="none"
      />
      <Pressable onPress={onContinue} style={{ padding: 14, borderRadius: 12, backgroundColor: "#111" }}>
        <Text style={{ color: "#fff", textAlign: "center", fontWeight: "700" }}>
          Tiếp tục
        </Text>
      </Pressable>
      <Text style={{ opacity: 0.65 }}>
        (Demo để chạy ngay) Bước sau sẽ đổi sang OTP số điện thoại.
      </Text>
    </View>
  );
}
TSX

cat > app/home.tsx <<'TSX'
import { useEffect, useState } from "react";
import { View, Text, TextInput, Pressable, FlatList } from "react-native";
import { router } from "expo-router";
import { getMe, findUserByPhone, createDirectChat } from "../src/userRepo";
import { listMyChats } from "../src/chatRepo";

export default function Home() {
  const [mePhone, setMePhone] = useState<string>("");
  const [searchPhone, setSearchPhone] = useState("");
  const [status, setStatus] = useState("");
  const [chats, setChats] = useState<{ id: string; title: string }[]>([]);

  async function refresh() {
    const me = await getMe();
    setMePhone(me.phone);
    const list = await listMyChats(me.phone);
    setChats(list);
  }

  useEffect(() => { refresh(); }, []);

  async function onSearchAndChat() {
    setStatus("");
    const targetPhone = searchPhone.trim();
    if (!targetPhone) return;

    const me = await getMe();
    if (targetPhone === me.phone) {
      setStatus("Không thể chat với chính mình 😅");
      return;
    }

    const u = await findUserByPhone(targetPhone);
    if (!u) {
      setStatus("Người này chưa có tài khoản. (Bước sau: gửi mã/link mời)");
      return;
    }

    const chatId = await createDirectChat(me.phone, targetPhone);
    router.push(`/chat/${chatId}`);
  }

  return (
    <View style={{ flex: 1, padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 16, fontWeight: "800" }}>Bạn: {mePhone || "..."}</Text>

      <View style={{ borderWidth: 1, borderRadius: 12, padding: 12, gap: 8 }}>
        <Text style={{ fontWeight: "800" }}>Nhắn theo số điện thoại (WhatsApp-style)</Text>
        <TextInput
          value={searchPhone}
          onChangeText={setSearchPhone}
          placeholder="Nhập SĐT người cần nhắn"
          style={{ borderWidth: 1, borderRadius: 12, padding: 12 }}
          autoCapitalize="none"
        />
        <Pressable onPress={onSearchAndChat} style={{ padding: 12, borderRadius: 12, backgroundColor: "#111" }}>
          <Text style={{ color: "#fff", textAlign: "center", fontWeight: "800" }}>
            Tìm & Nhắn
          </Text>
        </Pressable>
        {!!status && <Text style={{ color: "#b00" }}>{status}</Text>}
      </View>

      <View style={{ flex: 1, gap: 8 }}>
        <Text style={{ fontWeight: "800" }}>Chats</Text>
        <FlatList
          data={chats}
          keyExtractor={(x) => x.id}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => router.push(`/chat/${item.id}`)}
              style={{ padding: 12, borderWidth: 1, borderRadius: 12 }}
            >
              <Text style={{ fontWeight: "800" }}>{item.title}</Text>
              <Text style={{ opacity: 0.6, fontSize: 12 }}>{item.id}</Text>
            </Pressable>
          )}
        />
      </View>
    </View>
  );
}
TSX

cat > app/chat/[id].tsx <<'TSX'
import { useLocalSearchParams } from "expo-router";
import { useEffect, useState } from "react";
import { View, Text, TextInput, Pressable, FlatList } from "react-native";
import { getMe } from "../../src/userRepo";
import { listenMessages, sendMessage, getChatTitle } from "../../src/chatRepo";

export default function Chat() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [mePhone, setMePhone] = useState("");
  const [title, setTitle] = useState("");
  const [text, setText] = useState("");
  const [msgs, setMsgs] = useState<{ id: string; from: string; text: string; ts: number }[]>([]);

  useEffect(() => {
    let unsub: null | (() => void) = null;

    (async () => {
      const me = await getMe();
      setMePhone(me.phone);
      setTitle(await getChatTitle(String(id), me.phone));
      unsub = listenMessages(String(id), (items) => setMsgs(items));
    })();

    return () => { if (unsub) unsub(); };
  }, [id]);

  async function onSend() {
    const t = text.trim();
    if (!t) return;
    setText("");
    await sendMessage(String(id), mePhone, t);
  }

  return (
    <View style={{ flex: 1, padding: 12, gap: 8 }}>
      <Text style={{ fontWeight: "800" }}>{title}</Text>

      <FlatList
        data={msgs}
        keyExtractor={(m) => m.id}
        inverted
        contentContainerStyle={{ gap: 8 }}
        renderItem={({ item }) => (
          <View style={{
            alignSelf: item.from === mePhone ? "flex-end" : "flex-start",
            maxWidth: "85%",
            padding: 10,
            borderRadius: 12,
            borderWidth: 1
          }}>
            <Text style={{ fontSize: 12, opacity: 0.6 }}>{item.from}</Text>
            <Text>{item.text}</Text>
          </View>
        )}
      />

      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput
          value={text}
          onChangeText={setText}
          placeholder="Nhắn gì đó..."
          style={{ flex: 1, borderWidth: 1, borderRadius: 12, padding: 12 }}
        />
        <Pressable onPress={onSend} style={{ padding: 12, borderRadius: 12, backgroundColor: "#111" }}>
          <Text style={{ color: "#fff", fontWeight: "800" }}>Gửi</Text>
        </Pressable>
      </View>
    </View>
  );
}
TSX

cat > src/firebase.ts <<'TS'
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY!,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN!,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID!,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET!,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID!
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
TS

cat > src/userRepo.ts <<'TS'
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "./firebase";

let ME_PHONE = "";

export async function upsertUserByPhone(phone: string) {
  ME_PHONE = phone;
  const ref = doc(db, "users", phone);
  await setDoc(ref, {
    phone,
    displayName: phone,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  }, { merge: true });
}

export async function getMe() {
  if (!ME_PHONE) throw new Error("Chưa đăng nhập");
  return { phone: ME_PHONE };
}

export async function findUserByPhone(phone: string) {
  const ref = doc(db, "users", phone);
  const snap = await getDoc(ref);
  if (!snap.exists()) return null;
  return snap.data() as { phone: string; displayName: string };
}

export async function createDirectChat(mePhone: string, otherPhone: string) {
  const [a, b] = [mePhone, otherPhone].sort();
  const chatId = `dm_${a}_${b}`;
  const ref = doc(db, "chats", chatId);
  await setDoc(ref, {
    type: "dm",
    members: [a, b],
    updatedAt: serverTimestamp()
  }, { merge: true });
  return chatId;
}
TS

cat > src/chatRepo.ts <<'TS'
import {
  collection, doc, getDoc, onSnapshot, orderBy, query, setDoc, addDoc, serverTimestamp, where, getDocs
} from "firebase/firestore";
import { db } from "./firebase";

export async function getChatTitle(chatId: string, mePhone: string) {
  const ref = doc(db, "chats", chatId);
  const snap = await getDoc(ref);
  if (!snap.exists()) return "Chat";
  const data = snap.data() as any;
  if (data.type === "dm") {
    const other = (data.members || []).find((x: string) => x !== mePhone) || "Bạn";
    return other;
  }
  return data.title || "Nhóm";
}

export function listenMessages(chatId: string, cb: (items: any[]) => void) {
  const q = query(collection(db, "chats", chatId, "messages"), orderBy("ts", "desc"));
  return onSnapshot(q, (snap) => {
    const items = snap.docs.map((d) => {
      const v = d.data() as any;
      return { id: d.id, from: v.from, text: v.text, ts: v.ts?.toMillis?.() ?? 0 };
    });
    cb(items);
  });
}

export async function sendMessage(chatId: string, from: string, text: string) {
  await addDoc(collection(db, "chats", chatId, "messages"), {
    from,
    text,
    ts: serverTimestamp()
  });
  await setDoc(doc(db, "chats", chatId), { updatedAt: serverTimestamp() }, { merge: true });
}

export async function listMyChats(mePhone: string) {
  const q = query(collection(db, "chats"), where("members", "array-contains", mePhone));
  const snap = await getDocs(q);
  return snap.docs.map((d) => {
    const v = d.data() as any;
    let title = d.id;
    if (v.type === "dm") {
      const other = (v.members || []).find((x: string) => x !== mePhone) || "Bạn";
      title = other;
    } else if (v.type === "group") {
      title = v.title || "Nhóm";
    }
    return { id: d.id, title };
  });
}
TS

echo "==> Installing dependencies..."
npm install

echo
echo "✅ Done! Next:"
echo "1) Create .env with Firebase keys"
echo "2) Run: npm run start"
