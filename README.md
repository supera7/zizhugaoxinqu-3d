# 紫竹高新区 · 3D 沙盘

在「联创之星 3D」项目框架上改做的静态网站，无需构建。把本文件夹上传到任意静态托管（如 GitHub Pages）即可访问 index.html。

- index.html：页面本体，3D 沙盘用 Three.js 0.160（从 cdn.jsdelivr.net 加载）。沙盘按 OpenStreetMap 真实数据生成：1137 个建筑轮廓、道路、黄浦江与兰香湖等水系、绿地（© OpenStreetMap 贡献者，ODbL 协议，数据内嵌在 window.OSM）。未标注层数的楼按片区估算高度；兰香湖周边楼盘在 OSM 中只有用地范围，楼栋为示意。
- assets/：21 张 Wikimedia Commons 实拍照片（紫竹高新区站、紫叶广场与旗杆、信息数码港、研发基地、交大与华东师大闵行校区、黄浦江滨江公园），按 CC BY / CC BY-SA / 公有领域协议使用，作者与协议列在页面“出处与授权”一节；裁切为 4:3 的 BY-SA 照片同样以 BY-SA 协议提供。
- 新闻照片不存放在本地：页面直接引用原报道的图片地址（no-referrer），版权归原媒体所有。原站限制外链时（例如 claude.ai 预览页），会自动跳过，改显示该分区的 3D 沙盘渲染图，并附原报道链接。

修改分区文字或照片：编辑 index.html 中 `window.SPACES`（分区）和 `window.SRC`（出处）。
本地预览：在本文件夹运行 `python3 -m http.server`，打开 http://localhost:8000（直接双击打开时，本地照片无法贴到 3D 楼面上）。

## 会议室预约的跨设备同步

预约数据存放在 Supabase 云数据库（免费额度足够），所有电脑和手机共用一份排期：

1. 在 Supabase 新建项目，打开 SQL Editor，粘贴并运行 `supabase/booking.sql`。
2. 在 Project Settings → API 复制 Project URL 和 publishable（anon）key。
3. 填到 `index.html` 里的 `window.BOOKING_CLOUD={url:"…",key:"…"}`。这两项是公开的前端配置，可以放进网页。

时间冲突由数据库的排他约束判定，多台设备同时提交也只会成功一个。页面约每 10 秒自动刷新一次。
预约只能在提交它的那台设备上取消；管理员可以在 Supabase 的 Table Editor 里直接删除。
没有填写配置时，页面会退回到“仅本机”演示模式。
