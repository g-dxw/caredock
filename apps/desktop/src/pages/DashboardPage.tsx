import { ArrowRight, BedDouble, CalendarCheck2, CircleAlert, Clock3, HandCoins, Home, PackageCheck, UsersRound } from "lucide-react";
import { demoMeta, institution } from "@anyangtai/demo-data";
import { Badge, Button, PageHeader, Progress, SceneBadge, SectionCard, StatCard } from "../components/Ui";

export function DashboardPage({ onNavigate }: { onNavigate: (page: "institution" | "sites" | "elders" | "relationships") => void }) {
  return <>
    <PageHeader eyebrow={`工作台 / ${demoMeta.label}`} title="晚上好，陈立新" description={`${institution.name} · 今天是 2026年7月18日，星期六`} actions={<Button variant="secondary" onClick={() => onNavigate("institution")}>查看机构资料<ArrowRight size={16} /></Button>} />
    <div className="stats-grid stats-grid--4"><StatCard label="今日服务安排" value="38" helper="待处理 7 项" icon={<CalendarCheck2 size={19} />} /><StatCard label="今日到店" value="13 / 20" helper="日间容量使用 65%" icon={<UsersRound size={19} />} tone="blue" /><StatCard label="住宿床位" value="9 / 12" helper="空闲 3 张" icon={<BedDouble size={19} />} tone="violet" /><StatCard label="本月待收" value="¥8,460" helper="6 位付款人" icon={<HandCoins size={19} />} tone="amber" /></div>
    <div className="dashboard-grid">
      <SectionCard title="今日待办" description="按紧急程度排序" action={<button className="table-link">查看全部</button>}>
        <div className="task-list"><button type="button" onClick={() => onNavigate("relationships")}><span className="task-priority task-priority--red"><CircleAlert size={16} /></span><div><strong>许建国喘息服务将于2天后结束</strong><small>需要确认离院时间、费用和资源释放</small></div><Badge tone="red">需处理</Badge></button><button type="button" onClick={() => onNavigate("elders")}><span className="task-priority task-priority--amber"><Clock3 size={16} /></span><div><strong>2份老人档案等待补充联系信息</strong><small>资料可后补，但启用服务关系前必须存在可联系对象</small></div><Badge tone="amber">资料</Badge></button><button type="button" onClick={() => onNavigate("sites")}><span className="task-priority task-priority--blue"><BedDouble size={16} /></span><div><strong>助浴间出现维护提醒</strong><small>云栖中心站 · 建议确认今天剩余4个预约</small></div><Badge tone="blue">场地</Badge></button><button type="button"><span className="task-priority task-priority--green"><PackageCheck size={16} /></span><div><strong>日间乐龄月包新版本待发布</strong><small>不会覆盖已有服务关系的历史快照</small></div><Badge tone="green">套餐</Badge></button></div>
      </SectionCard>
      <SectionCard title="机构运行概览" description="匿名演示数据">
        <div className="operation-list"><div><span><Home size={17} />居家上门</span><strong>31 人</strong><Progress value={78} /></div><div><span><UsersRound size={17} />日间照料</span><strong>18 人</strong><Progress value={65} /></div><div><span><BedDouble size={17} />集中住宿</span><strong>9 人</strong><Progress value={75} /></div><div><span><CalendarCheck2 size={17} />喘息服务</span><strong>2 人</strong><Progress value={100} /></div></div>
        <div className="demo-notice"><span>演示</span><div><strong>当前为匿名演示机构</strong><small>{demoMeta.notice}</small></div></div>
      </SectionCard>
    </div>
    <SectionCard title="近期动态" description="关键变更和业务节点均保留操作轨迹">
      <div className="activity-table"><div className="activity-row activity-row--header"><span>时间</span><span>对象</span><span>动作</span><span>场景</span><span>操作人员</span></div><div className="activity-row"><span>今天 16:42</span><span><strong>林淑兰</strong></span><span>确认日间离店记录</span><span><SceneBadge scene="日间" /></span><span>张晓宁</span></div><div className="activity-row"><span>今天 15:18</span><span><strong>许建国</strong></span><span>更新喘息结束提醒</span><span><SceneBadge scene="喘息" /></span><span>陈立新</span></div><div className="activity-row"><span>今天 11:06</span><span><strong>沈玉芳</strong></span><span>补录居家保洁执行</span><span><SceneBadge scene="居家" /></span><span>李海峰</span></div><div className="activity-row"><span>昨天 17:30</span><span><strong>周伯安</strong></span><span>确认住宿月度价格快照</span><span><SceneBadge scene="住宿" /></span><span>陈立新</span></div></div>
    </SectionCard>
  </>;
}
