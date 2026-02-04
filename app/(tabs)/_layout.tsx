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
