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
