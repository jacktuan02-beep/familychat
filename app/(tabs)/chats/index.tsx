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
