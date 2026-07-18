import { useMemo, useState } from "react";
import { BadgeCheck, BriefcaseBusiness, ChevronRight, Filter, Plus, SearchCheck, UserRoundCheck, UsersRound } from "lucide-react";
import { staff } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, SearchField, SectionCard, StatCard } from "../components/Ui";

export function StaffPage() {
  const [query, setQuery] = useState("");
  const [selectedId, setSelectedId] = useState<string>(staff[0].id);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const filtered = useMemo(() => staff.filter((person) => `${person.name}${person.roles.join("")}${person.sites.join("")}`.includes(query)), [query]);
  const selected = staff.find((person) => person.id === selectedId) ?? staff[0];

  return (
    <>
      <PageHeader eyebrow="基础配置 / 员工" title="员工与任职" description="一个人员可拥有多个岗位、跨站点任职，并保留资格和在职历史。" actions={<Button onClick={() => setDrawerOpen(true)}><Plus size={16} />新增员工</Button>} />
      <div className="stats-grid stats-grid--4">
        <StatCard label="在册人员" value="20" helper="在职18 · 离职2" icon={<UsersRound size={19} />} />
        <StatCard label="护理人员" value="11" helper="含兼职2人" icon={<UserRoundCheck size={19} />} tone="blue" />
        <StatCard label="岗位任职" value="27" helper="6人拥有多个岗位" icon={<BriefcaseBusiness size={19} />} tone="violet" />
        <StatCard label="资格待完善" value="1" helper="不会硬阻断排班" icon={<BadgeCheck size={19} />} tone="amber" />
      </div>

      <SectionCard className="flush-card">
        <div className="table-toolbar"><div className="table-toolbar__left"><SearchField value={query} onChange={setQuery} placeholder="搜索姓名、岗位或站点" /><Button variant="secondary" size="sm"><Filter size={15} />筛选</Button></div><div className="toolbar-note"><SearchCheck size={16} />资格要求只提示，可由有权限人员确认覆盖</div></div>
        <div className="staff-layout">
          <div className="data-table-wrap staff-table-wrap">
            <table className="data-table data-table--selectable">
              <thead><tr><th>员工</th><th>岗位</th><th>服务站点</th><th>资格</th><th>状态</th><th /></tr></thead>
              <tbody>{filtered.map((person) => <tr key={person.id} className={selectedId === person.id ? "is-selected" : ""} onClick={() => setSelectedId(person.id)}><td><div className="person-cell"><span>{person.initials}</span><div><strong>{person.name}</strong><small>{person.gender} · {person.phone}</small></div></div></td><td><div className="stacked-text"><strong>{person.roles[0]}</strong>{person.roles[1] && <small>兼任 {person.roles[1]}</small>}</div></td><td>{person.sites.join("、")}</td><td><span className="qualification-text">{person.qualification}</span></td><td><Badge tone={person.status === "在职" ? "green" : "amber"}>{person.status}</Badge></td><td><ChevronRight size={16} /></td></tr>)}</tbody>
            </table>
          </div>
          <aside className="record-detail">
            <div className="record-detail__hero"><div className="avatar avatar--large">{selected.initials}</div><div><h3>{selected.name}</h3><p>{selected.gender} · {selected.phone}</p><Badge tone={selected.status === "在职" ? "green" : "amber"}>{selected.status}</Badge></div></div>
            <div className="record-detail__section"><div className="record-detail__title"><strong>当前岗位</strong><button type="button">维护任职</button></div>{selected.roles.map((role, index) => <div className="role-card" key={role}><div><BriefcaseBusiness size={17} /><span><strong>{role}</strong><small>{index === 0 ? "主要岗位" : "兼任岗位"}</small></span></div><small>{selected.sites.join("、")}</small></div>)}</div>
            <div className="record-detail__section"><div className="record-detail__title"><strong>资格与证书</strong><button type="button">查看全部</button></div><div className="credential-card"><BadgeCheck size={19} /><div><strong>{selected.qualification}</strong><span>{selected.status === "待完善" ? "建议补充证书附件" : "已核验 · 当前有效"}</span></div></div></div>
            <div className="record-detail__section"><div className="record-detail__title"><strong>可服务场景</strong></div><div className="badge-row"><Badge tone="blue">居家</Badge><Badge tone="green">日间</Badge><Badge tone="violet">住宿</Badge></div><p className="detail-note">服务场景来自站点任职范围，不等同于系统登录权限。</p></div>
            <Button variant="secondary" className="full-width">编辑员工资料</Button>
          </aside>
        </div>
      </SectionCard>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title="新增员工" description="先建立人员主档，再配置任职、站点范围和资格。">
        <div className="form-section"><div className="form-section__title"><span>1</span><div><h3>人员基本信息</h3><p>不代表创建登录账号</p></div></div><div className="form-grid"><Field label="姓名" required><input placeholder="请输入姓名" /></Field><Field label="性别"><select><option>女</option><option>男</option><option>未说明</option></select></Field><Field label="手机号码"><input placeholder="用于机构内部联系" /></Field><Field label="人员类型" required><select><option>正式员工</option><option>兼职人员</option><option>志愿者</option><option>外部协作人员</option></select></Field></div></div>
        <div className="form-section"><div className="form-section__title"><span>2</span><div><h3>首个任职</h3><p>保存后可以继续增加多个岗位和站点</p></div></div><div className="form-grid"><Field label="岗位" required><select><option>护理员</option><option>护理主管</option><option>社工</option><option>助餐员</option></select></Field><Field label="主要站点"><select><option>云栖中心站</option><option>杏林社区服务点</option><option>全部站点</option></select></Field><Field label="入职日期"><input type="date" defaultValue="2026-07-18" /></Field><Field label="部门（可选）"><select><option>不设置部门</option><option>照护部</option><option>综合运营部</option></select></Field></div></div>
      </Drawer>
    </>
  );
}
