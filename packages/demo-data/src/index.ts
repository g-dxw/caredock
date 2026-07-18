export const demoDataContainsRealData = false as const;

export const institution = {
  name: "云栖颐养服务中心",
  shortName: "云栖颐养",
  code: "DEMO-AYT-001",
  nature: "民办非企业单位",
  operatorType: "社会力量运营",
  unifiedCreditCode: "9132**********5X",
  legalRepresentative: "周**",
  phone: "0512-88****16",
  address: "江苏省苏州市姑苏区春和路 18 号",
  establishedOn: "2021-06-18",
  status: "正常运营",
  formalBedCount: 12,
  enabledSceneCount: 4,
  activeStaffCount: 18,
  activeElderCount: 46,
} as const;

export const capabilities = [
  { key: "home", name: "居家上门", enabled: true, summary: "上门照护、助洁、助餐与陪诊", metric: "31 位服务对象" },
  { key: "day", name: "日间照料", enabled: true, summary: "到店照料、活动、午休与助餐", metric: "日容量 20 人" },
  { key: "residential", name: "集中住宿", enabled: true, summary: "小规模长期入住和日常照护", metric: "12 张正式床位" },
  { key: "respite", name: "喘息服务", enabled: true, summary: "短期托养，共用可用住宿资源", metric: "2 张可共享床位" },
] as const;

export const modulePreferences = [
  { key: "institution", name: "机构资料", group: "基础配置", recommended: true, enabled: true },
  { key: "sites", name: "场地与资源", group: "基础配置", recommended: true, enabled: true },
  { key: "staff", name: "员工管理", group: "基础配置", recommended: true, enabled: true },
  { key: "catalog", name: "服务目录", group: "服务配置", recommended: true, enabled: true },
  { key: "pricing", name: "收费与套餐", group: "服务配置", recommended: true, enabled: true },
  { key: "elders", name: "老人档案", group: "服务对象", recommended: true, enabled: true },
  { key: "relationships", name: "服务关系", group: "服务对象", recommended: true, enabled: true },
  { key: "inventory", name: "物资管理", group: "可选工具", recommended: false, enabled: false },
] as const;

export const sites = [
  {
    id: "site-1",
    name: "云栖中心站",
    code: "SITE-001",
    type: "综合服务站",
    address: "姑苏区春和路 18 号",
    scenes: ["居家", "日间", "住宿", "喘息"],
    status: "运营中",
    spaces: 9,
    formalBeds: 12,
    occupiedBeds: 9,
    dayCapacity: 20,
    homeDistricts: ["姑苏区", "虎丘区"],
  },
  {
    id: "site-2",
    name: "杏林社区服务点",
    code: "SITE-002",
    type: "社区服务点",
    address: "姑苏区杏林街 6 号",
    scenes: ["居家", "日间"],
    status: "运营中",
    spaces: 3,
    formalBeds: 0,
    occupiedBeds: 0,
    dayCapacity: 12,
    homeDistricts: ["姑苏区"],
  },
] as const;

export const spaces = [
  { name: "1F 日间照料区", type: "日间区域", capacity: "20 人", usage: "当前 13 人", status: "正常" },
  { name: "2F 住宿区", type: "住宿区域", capacity: "8 张床", usage: "已入住 7 张", status: "正常" },
  { name: "3F 住宿区", type: "住宿区域", capacity: "4 张床", usage: "已入住 2 张", status: "正常" },
  { name: "多功能活动室", type: "公共空间", capacity: "30 人", usage: "今日 2 场活动", status: "正常" },
  { name: "助浴间", type: "服务空间", capacity: "1 工位", usage: "今日 4 单", status: "维护提醒" },
] as const;

export const staff = [
  { id: "s1", name: "张晓宁", initials: "张", gender: "女", phone: "138****0921", roles: ["护理主管", "护理员"], sites: ["云栖中心站"], qualification: "养老护理员（高级）", status: "在职" },
  { id: "s2", name: "陈立新", initials: "陈", gender: "男", phone: "139****6038", roles: ["机构负责人"], sites: ["全部站点"], qualification: "安全管理员", status: "在职" },
  { id: "s3", name: "赵文静", initials: "赵", gender: "女", phone: "136****7112", roles: ["社工", "活动专员"], sites: ["云栖中心站", "杏林社区服务点"], qualification: "社会工作师", status: "在职" },
  { id: "s4", name: "李海峰", initials: "李", gender: "男", phone: "137****5248", roles: ["护理员"], sites: ["云栖中心站"], qualification: "养老护理员（中级）", status: "在职" },
  { id: "s5", name: "王月琴", initials: "王", gender: "女", phone: "135****3186", roles: ["助餐员"], sites: ["杏林社区服务点"], qualification: "健康证 · 2027-03到期", status: "在职" },
  { id: "s6", name: "孙悦", initials: "孙", gender: "女", phone: "158****4420", roles: ["兼职护理员"], sites: ["云栖中心站"], qualification: "护理培训证明", status: "待完善" },
] as const;

export const serviceItems = [
  { id: "svc-1", code: "HL-001", name: "基础生活照护", category: "生活照料", scenes: ["住宿", "喘息"], duration: "30 分钟", evidence: "服务记录", price: "套餐内", status: "启用" },
  { id: "svc-2", code: "JJ-001", name: "居家保洁", category: "居家支持", scenes: ["居家"], duration: "120 分钟", evidence: "前后照片", price: "¥80 / 次", status: "启用" },
  { id: "svc-3", code: "ZC-001", name: "长者助餐", category: "助餐服务", scenes: ["居家", "日间", "住宿"], duration: "—", evidence: "签收记录", price: "¥18 / 份", status: "启用" },
  { id: "svc-4", code: "JK-001", name: "基础健康监测", category: "健康管理", scenes: ["居家", "日间", "住宿", "喘息"], duration: "15 分钟", evidence: "指标记录", price: "¥12 / 次", status: "启用" },
  { id: "svc-5", code: "YL-001", name: "益智活动小组", category: "文娱社工", scenes: ["日间", "住宿"], duration: "60 分钟", evidence: "签到与活动记录", price: "套餐内", status: "启用" },
  { id: "svc-6", code: "ZX-001", name: "陪诊服务", category: "陪同服务", scenes: ["居家"], duration: "半天", evidence: "就诊凭证", price: "¥160 / 半天", status: "草稿" },
] as const;

export const chargeItems = [
  { code: "FEE-001", name: "居家保洁服务费", unit: "次", linkedService: "居家保洁", priceScope: "全机构", currentPrice: "¥80.00", status: "有效" },
  { code: "FEE-002", name: "助餐费", unit: "份", linkedService: "长者助餐", priceScope: "按站点", currentPrice: "¥16—18", status: "有效" },
  { code: "FEE-003", name: "健康监测服务费", unit: "次", linkedService: "基础健康监测", priceScope: "全机构", currentPrice: "¥12.00", status: "有效" },
  { code: "FEE-004", name: "住宿床位费", unit: "月", linkedService: "—", priceScope: "按床型", currentPrice: "¥1,800—2,400", status: "有效" },
  { code: "FEE-005", name: "基础管理费", unit: "月", linkedService: "—", priceScope: "住宿场景", currentPrice: "¥300.00", status: "有效" },
] as const;

export const packages = [
  { id: "pkg-1", name: "居家安心月包", code: "PKG-HOME-01", scene: "居家", cycle: "自然月", price: "¥399", services: "4 项服务", quota: "保洁2次 · 监测4次", users: 16, status: "销售中" },
  { id: "pkg-2", name: "日间乐龄月包", code: "PKG-DAY-01", scene: "日间", cycle: "自然月", price: "¥980", services: "5 项服务", quota: "到店12天 · 午餐12份", users: 11, status: "销售中" },
  { id: "pkg-3", name: "喘息照护7日包", code: "PKG-RSP-01", scene: "喘息", cycle: "7天", price: "¥1,680", services: "6 项服务", quota: "住宿7晚 · 日常照护", users: 2, status: "销售中" },
] as const;

export const elders = [
  { id: "e1", name: "林淑兰", initials: "林", gender: "女", age: 78, phone: "本人未留手机", idCard: "3205**********1228", scenes: ["日间", "居家"], contact: "林志远 · 儿子", contactPhone: "138****6117", status: "服务中", lastActivity: "今天 09:12 到店" },
  { id: "e2", name: "周伯安", initials: "周", gender: "男", age: 82, phone: "139****8205", idCard: "3205**********4811", scenes: ["住宿"], contact: "周敏 · 女儿", contactPhone: "137****9201", status: "服务中", lastActivity: "2F-203-01 床" },
  { id: "e3", name: "沈玉芳", initials: "沈", gender: "女", age: 74, phone: "136****3772", idCard: "3205**********2026", scenes: ["居家"], contact: "本人", contactPhone: "136****3772", status: "服务中", lastActivity: "明天 14:00 上门" },
  { id: "e4", name: "许建国", initials: "许", gender: "男", age: 86, phone: "本人未留手机", idCard: "3205**********711X", scenes: ["喘息"], contact: "许雯 · 女儿", contactPhone: "159****5809", status: "即将到期", lastActivity: "7月20日结束" },
  { id: "e5", name: "蒋慧娟", initials: "蒋", gender: "女", age: 69, phone: "158****0922", idCard: "3205**********6824", scenes: [], contact: "蒋慧娟 · 本人", contactPhone: "158****0922", status: "待开通", lastActivity: "档案资料已完成 80%" },
] as const;

export const relationships = [
  { id: "rel-day", elderId: "e1", scene: "日间", title: "日间照料服务", status: "服务中", since: "2025-11-01", site: "云栖中心站", packageName: "日间乐龄月包", agreement: "XY-2025-1108", resource: "1F 日间照料区", nextAction: "今天 16:30 离店" },
  { id: "rel-home", elderId: "e1", scene: "居家", title: "居家上门服务", status: "服务中", since: "2026-03-01", site: "云栖中心站", packageName: "居家安心月包", agreement: "XY-2026-0312", resource: "姑苏区 · 机构服务范围内", nextAction: "7月19日 10:00 健康监测" },
  { id: "rel-res", elderId: "e2", scene: "住宿", title: "集中住宿服务", status: "服务中", since: "2024-08-16", site: "云栖中心站", packageName: "基础照护月包", agreement: "XY-2024-0803", resource: "2F-203-01 床", nextAction: "本月费用待确认" },
  { id: "rel-rsp", elderId: "e4", scene: "喘息", title: "短期喘息服务", status: "即将到期", since: "2026-07-13", site: "云栖中心站", packageName: "喘息照护7日包", agreement: "XY-2026-0718", resource: "3F-302-02 床（共享）", nextAction: "7月20日办理结束" },
] as const;

export const relationshipSnapshots = {
  packageName: "日间乐龄月包",
  packageVersion: "V3 · 2026-06-01生效",
  packagePrice: "¥980.00 / 自然月",
  entitlements: ["日间到店 12 天", "午餐 12 份", "健康监测 4 次", "益智活动 不限次"],
  pricing: [
    { name: "套餐月费", standard: "¥980.00", actual: "¥980.00", basis: "套餐版本 V3" },
    { name: "超额午餐", standard: "¥18.00 / 份", actual: "¥18.00 / 份", basis: "中心站价格 V2" },
  ],
} as const;

export const demoMeta = {
  label: "匿名演示机构",
  updatedAt: "2026-07-18 22:30",
  notice: "所有姓名、电话、证件号和业务记录均为虚构数据",
} as const;
