// 紫竹会议室预约 · 国内访问中转（Cloudflare Worker）
// 浏览器 → 你的域名（Cloudflare）→ Supabase 数据库
// 只放行网页需要的三个接口：读取排期、提交预约、取消预约。
const UPSTREAM = "https://aqzhelyolbplsxfpqxbn.supabase.co/rest/v1/";
const KEY = "sb_publishable_e4vlR2u7wa9F_HpvgU_3bw_pkPEufur"; // 可公开的前端密钥
const ORIGINS = ["https://supera7.github.io"];

export default {
  async fetch(req) {
    const url = new URL(req.url);
    const origin = req.headers.get("Origin") || "";
    const cors = {
      "Access-Control-Allow-Origin": ORIGINS.includes(origin) ? origin : ORIGINS[0],
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, apikey, Authorization",
      "Access-Control-Max-Age": "86400",
      "Vary": "Origin",
    };
    const json = (body, status) =>
      new Response(body, { status, headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" } });

    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

    if (url.pathname === "/") return json('{"ok":true}', 200);
    const path = url.pathname.replace(/^\/rest\/v1\//, "");
    const allowed =
      (req.method === "GET" && path === "bookings") ||
      (req.method === "POST" && (path === "rpc/book" || path === "rpc/cancel_booking"));
    if (!allowed) return json('{"message":"not found"}', 404);

    try {
      const r = await fetch(UPSTREAM + path + url.search, {
        method: req.method,
        headers: { apikey: KEY, "Content-Type": "application/json" },
        body: req.method === "POST" ? await req.text() : undefined,
      });
      return json(await r.text(), r.status);
    } catch (e) {
      return json('{"message":"upstream_unreachable"}', 502);
    }
  },
};
