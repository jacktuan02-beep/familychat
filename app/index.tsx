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
