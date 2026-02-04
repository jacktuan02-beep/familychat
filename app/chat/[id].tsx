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
