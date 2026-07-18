import { useMemo, useState } from "react";
import { CalendarClock, ChevronRight, ContactRound, FileCheck2, Filter, MapPinned, Plus, UserRoundPlus, UsersRound } from "lucide-react";
import { elders, relationships } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, Progress, SceneBadge, SearchField, SectionCard, StatCard } from "../components/Ui";

export function EldersPage({ onOpenRelationships }: { onOpenRelationships: () => void }) {
  const [query, setQuery] = useState("");
  const [selectedId, setSelectedId] = useState<string>(elders[0].id);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const filtered = useMemo(() => elders.filter((elder) => `${elder.name}${elder.contact}${elder.idCard}`.includes(query)), [query]);
  const selected = elders.find((elder) => elder.id === selectedId) ?? elders[0];
  const selectedRelationships = relationships.filter((relationship) => relationship.elderId === selected.id);

  return (
    <>
      <PageHeader eyebrow="服务对象 / 老人档案" title="老人档案" description="身份、联系人和稳定资料只建一份；服务场景变化通过独立服务关系记录。" actions={<Button onClick={() => setDrawerOpen(true)}><UserRoundPlus size={16} />新建老人档案</Button>} />
      <div className="stats-grid stats-grid--4">
        <StatCard label="服务中老人" value="46" helper="本月新增 3 人" icon={<UsersRound size={19} />} />
        <StatCard label="多场景服务" value="8" helper="同一主档关联多个关系" icon={<ContactRound size={19} />} tone="blue" />
        <StatCard label="待开通服务" value="2" helper="档案已建立" icon={<CalendarClock size={19} />} tone="amber" />
        <StatCard label="资料待完善" value="5" helper="不会阻断建档" icon={<FileCheck2 size={19} />} tone="violet" />
      </div>

      <SectionCard className="flush-card">
        <div className="table-toolbar"><div className="table-toolbar__left"><SearchField value={query} onChange={setQuery} placeholder="搜索姓名、证件号或联系人" /><Button variant="secondary" size="sm"><Filter size={15} />服务状态</Button></div><span className="toolbar-note">敏感信息在列表中默认脱敏</span></div>
        <div className="elder-layout">
          <div className="elder-list">
            {filtered.map((elder) => <button key={elder.id} type="button" className={`elder-row ${selectedId === elder.id ? "is-active" : ""}`} onClick={() => setSelectedId(elder.id)}><div className="avatar">{elder.initials}</div><div className="elder-row__main"><div><strong>{elder.name}</strong><span>{elder.gender} · {elder.age}岁</span></div><div className="badge-row">{elder.scenes.length ? elder.scenes.map((scene) => <SceneBadge key={scene} scene={scene} />) : <Badge>暂无服务</Badge>}</div><small>{elder.lastActivity}</small></div><Badge tone={elder.status === "服务中" ? "green" : elder.status === "即将到期" ? "amber" : "gray"}>{elder.status}</Badge><ChevronRight size={16} /></button>)}
          </div>
          <aside className="elder-detail">
            <div className="elder-detail__hero"><div className="avatar avatar--xl">{selected.initials}</div><div><div className="title-with-status"><h2>{selected.name}</h2><Badge tone={selected.status === "服务中" ? "green" : "amber"}>{selected.status}</Badge></div><p>{selected.gender} · {selected.age}岁 · {selected.idCard}</p></div><Button variant="secondary" size="sm">编辑档案</Button></div>
            <div className="profile-completion"><div><strong>档案完整度</strong><span>{selected.status === "待开通" ? "80%" : "92%"}</span></div><Progress value={selected.status === "待开通" ? 80 : 92} /></div>
            <div className="elder-info-grid"><div><ContactRound size={18} /><span><small>主要联系对象</small><strong>{selected.contact}</strong><em>{selected.contactPhone}</em></span></div><div><MapPinned size={18} /><span><small>常用服务地址</small><strong>姑苏区春和街道</strong><em>详细地址已保存</em></span></div><div><FileCheck2 size={18} /><span><small>外部评估资料</small><strong>能力等级：轻度失能</strong><em>有效至 2027-01-20</em></span></div></div>
            <div className="relationship-heading"><div><h3>服务关系</h3><p>当前 {selectedRelationships.length} 条有效关系</p></div><Button size="sm" onClick={onOpenRelationships}><Plus size={15} />建立服务关系</Button></div>
            {selectedRelationships.length > 0 ? <div className="relationship-mini-list">{selectedRelationships.map((relationship) => <button type="button" key={relationship.id} onClick={onOpenRelationships}><div className={`scene-symbol scene-symbol--${relationship.scene === "居家" ? "home" : relationship.scene === "日间" ? "day" : relationship.scene === "住宿" ? "residential" : "respite"}`}>{relationship.scene.slice(0, 1)}</div><span><strong>{relationship.title}</strong><small>{relationship.site} · {relationship.since}起</small><em>{relationship.nextAction}</em></span><ChevronRight size={17} /></button>)}</div> : <div className="inline-empty"><strong>尚未建立服务关系</strong><span>老人主档可以先保存，资料允许后补。</span><Button size="sm" onClick={onOpenRelationships}>现在开通</Button></div>}
          </aside>
        </div>
      </SectionCard>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title="新建老人档案" description="先保存稳定主档和至少一个可联系对象，服务关系可稍后建立。">
        <div className="form-section"><div className="form-section__title"><span>1</span><div><h3>老人基本资料</h3><p>证件和健康资料允许后补</p></div></div><div className="form-grid"><Field label="姓名" required><input placeholder="请输入姓名" /></Field><Field label="性别"><select><option>女</option><option>男</option><option>未说明</option></select></Field><Field label="出生日期" required><input type="date" /></Field><Field label="证件类型"><select><option>居民身份证</option><option>其他证件</option><option>暂不填写</option></select></Field><Field label="证件号码"><input placeholder="保存后列表自动脱敏" /></Field><Field label="本人电话"><input placeholder="可留空，由联系人承担联系角色" /></Field></div></div>
        <div className="form-section"><div className="form-section__title"><span>2</span><div><h3>首个联系对象</h3><p>启用服务关系前至少存在一个可联系对象</p></div></div><div className="form-grid"><Field label="联系人姓名" required><input placeholder="老人本人也可作为联系对象" /></Field><Field label="与老人关系"><select><option>本人</option><option>子女</option><option>配偶</option><option>其他亲属</option></select></Field><Field label="手机或电话" required><input placeholder="至少填写一种联系方式" /></Field><Field label="联系角色"><select><option>主要联系人</option><option>紧急联系人</option><option>付款人</option><option>协议签署人</option></select></Field></div></div>
      </Drawer>
    </>
  );
}
