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
