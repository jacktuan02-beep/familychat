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
