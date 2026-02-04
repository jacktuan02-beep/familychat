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
