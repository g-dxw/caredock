import { useState } from "react";
import { AlertTriangle, BedDouble, CalendarDays, Check, ChevronRight, ClipboardSignature, FileStack, Home, MapPin, PackageCheck, Plus, ShieldCheck, UsersRound } from "lucide-react";
import { elders, relationshipSnapshots, relationships } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, SceneBadge, SectionCard, Segmented, StatCard } from "../components/Ui";

type RelationshipTab = "overview" | "agreement" | "snapshots";

const sceneIcons = { 居家: Home, 日间: UsersRound, 住宿: BedDouble, 喘息: CalendarDays } as const;

export function RelationshipsPage() {
  const [selectedId, setSelectedId] = useState<string>(relationships[0].id);
  const [tab, setTab] = useState<RelationshipTab>("overview");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const selected = relationships.find((relationship) => relationship.id === selectedId) ?? relationships[0];
  const elder = elders.find((item) => item.id === selected.elderId) ?? elders[0];
  const SceneIcon = sceneIcons[selected.scene as keyof typeof sceneIcons];

  return (
    <>
      <PageHeader eyebrow="服务对象 / 服务关系" title="四场景服务关系" description="每条关系独立保存场景资料、协议、资源以及启用时的套餐和价格快照。" actions={<Button onClick={() => setDrawerOpen(true)}><Plus size={16} />建立服务关系</Button>} />
      <div className="stats-grid stats-grid--4">
        <StatCard label="有效服务关系" value="54" helper="46 位老人" icon={<ShieldCheck size={19} />} />
        <StatCard label="居家 / 日间" value="31 / 18" helper="当前主要服务场景" icon={<Home size={19} />} tone="blue" />
        <StatCard label="住宿 / 喘息" value="9 / 2" helper="喘息占用共享资源" icon={<BedDouble size={19} />} tone="violet" />
        <StatCard label="即将到期" value="3" helper="未来 7 天内" icon={<AlertTriangle size={19} />} tone="amber" />
      </div>

      <div className="relationship-workbench">
        <aside className="relationship-sidebar">
          <div className="relationship-sidebar__header"><div><strong>近期服务关系</strong><span>{relationships.length} 条演示数据</span></div><button type="button"><Plus size={16} /></button></div>
          {relationships.map((relationship) => {
            const relationshipElder = elders.find((item) => item.id === relationship.elderId);
            const Icon = sceneIcons[relationship.scene as keyof typeof sceneIcons];
            return <button type="button" key={relationship.id} className={selectedId === relationship.id ? "is-active" : ""} onClick={() => { setSelectedId(relationship.id); setTab("overview"); }}><div className={`relationship-scene relationship-scene--${relationship.scene === "居家" ? "home" : relationship.scene === "日间" ? "day" : relationship.scene === "住宿" ? "residential" : "respite"}`}><Icon size={18} /></div><div><strong>{relationshipElder?.name} · {relationship.scene}</strong><span>{relationship.packageName}</span><small>{relationship.nextAction}</small></div><ChevronRight size={16} /></button>;
          })}
          <div className="matrix-note"><ShieldCheck size={18} /><div><strong>并存关系由规则矩阵检查</strong><span>住宿与喘息重叠阻断；住宿与居家/日间并存强提醒。</span></div></div>
        </aside>

        <main className="relationship-detail">
          <div className="relationship-detail__hero">
            <div className={`relationship-hero-icon relationship-hero-icon--${selected.scene === "居家" ? "home" : selected.scene === "日间" ? "day" : selected.scene === "住宿" ? "residential" : "respite"}`}><SceneIcon size={24} /></div>
            <div className="relationship-detail__identity"><div className="title-with-status"><h2>{elder.name} · {selected.title}</h2><Badge tone={selected.status === "服务中" ? "green" : "amber"}>{selected.status}</Badge></div><p>关系编号 {selected.id.toUpperCase()} · {selected.since} 起</p><div className="badge-row"><SceneBadge scene={selected.scene} /><Badge>{selected.site}</Badge></div></div>
            <Button variant="secondary">变更关系</Button>
          </div>

          <Segmented items={[{ value: "overview", label: "关系概览" }, { value: "agreement", label: "协议与资源" }, { value: "snapshots", label: "套餐与价格快照" }]} value={tab} onChange={setTab} />

          {tab === "overview" && <div className="relationship-tab-content">
            <div className="relationship-overview-grid">
              <SectionCard title="关系资料" description="当前有效版本 V2">
                <dl className="details-grid"><div><dt>服务场景</dt><dd>{selected.scene}</dd></div><div><dt>负责站点</dt><dd>{selected.site}</dd></div><div><dt>开始日期</dt><dd>{selected.since}</dd></div><div><dt>主要联系人</dt><dd>{elder.contact}</dd></div><div className="details-grid__wide"><dt>场景资料</dt><dd>{selected.scene === "居家" ? "服务地址：姑苏区春和街道 · 偏好上午上门" : selected.scene === "日间" ? "周一、周三、周五固定到店 · 1F日间照料区" : selected.scene === "住宿" ? "2F-203-01床 · 长期入住" : "2026-07-13 至 2026-07-20 · 7日喘息"}</dd></div></dl>
              </SectionCard>
              <SectionCard title="下一步事项" description="由当前关系状态推导">
                <div className="next-action-card"><CalendarDays size={20} /><div><strong>{selected.nextAction}</strong><span>系统仅提示，不自动改变关系状态。</span></div></div>
                <div className="mini-checks"><div><Check size={15} />主要联系人已确认</div><div><Check size={15} />协议在有效期内</div><div><Check size={15} />价格快照已保存</div></div>
              </SectionCard>
            </div>
            <SectionCard title="版本轨迹" description="关系变更新增版本，不覆盖历史。">
              <div className="timeline"><div className="is-current"><span /><div><strong>V2 · 当前有效</strong><small>2026-06-01 价格确认 · 操作人员：张晓宁</small><p>更新套餐到“{selected.packageName}”，保留原协议。</p></div></div><div><span /><div><strong>V1 · 初次开通</strong><small>{selected.since} · 操作人员：陈立新</small><p>建立{selected.scene}服务关系并保存首份套餐与价格快照。</p></div></div></div>
            </SectionCard>
          </div>}

          {tab === "agreement" && <div className="relationship-tab-content">
            <div className="agreement-grid"><SectionCard title="服务协议" action={<Badge tone="green">有效</Badge>}><div className="document-card"><div className="document-card__icon"><ClipboardSignature size={24} /></div><div><strong>{selected.agreement}</strong><span>{selected.title}协议</span><small>签署日期 {selected.since} · 附件 1 份</small></div><button type="button">查看附件</button></div><dl className="details-grid"><div><dt>甲方</dt><dd>{elder.name}</dd></div><div><dt>乙方</dt><dd>云栖颐养服务中心</dd></div><div><dt>主要签署人</dt><dd>{elder.contact}</dd></div><div><dt>协议状态</dt><dd>履行中</dd></div></dl></SectionCard><SectionCard title="资源分配" description="资源占用按有效期记录"><div className="resource-assignment"><div className={`scene-symbol scene-symbol--${selected.scene === "居家" ? "home" : selected.scene === "日间" ? "day" : selected.scene === "住宿" ? "residential" : "respite"}`}><MapPin size={19} /></div><div><strong>{selected.resource}</strong><span>{selected.site}</span><small>{selected.scene === "喘息" ? "短期共享用途，不复制床位" : "当前有效分配"}</small></div><Badge tone="green">已分配</Badge></div><div className="resource-rule"><ShieldCheck size={17} /><span>应用事务将在保存时检查资源场景、同一老人及时间重叠。</span></div></SectionCard></div>
          </div>}

          {tab === "snapshots" && <div className="relationship-tab-content">
            <div className="snapshot-banner"><FileStack size={21} /><div><strong>以下内容是关系启用或变更时的不可变快照</strong><span>以后修改目录名称、套餐版本或标准价格，都不会覆盖这里的历史依据。</span></div></div>
            <div className="snapshot-grid"><SectionCard title="套餐快照" action={<Badge tone="blue">{relationshipSnapshots.packageVersion}</Badge>}><div className="snapshot-package"><PackageCheck size={22} /><div><strong>{selected.packageName}</strong><span>{relationshipSnapshots.packagePrice}</span></div></div><div className="entitlement-list">{relationshipSnapshots.entitlements.map((entitlement) => <div key={entitlement}><Check size={15} /><span>{entitlement}</span></div>)}</div></SectionCard><SectionCard title="价格快照" description="标准价与本关系实际价分别保存"><div className="snapshot-pricing">{relationshipSnapshots.pricing.map((price) => <div key={price.name}><div><strong>{price.name}</strong><small>{price.basis}</small></div><span>{price.standard}</span><b>{price.actual}</b></div>)}</div></SectionCard></div>
          </div>}
        </main>
      </div>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title="建立服务关系" description="按步骤确认老人、场景、场景资料、协议、资源和发生时快照。">
        <div className="wizard-steps"><div className="is-active"><span>1</span><strong>对象与场景</strong></div><i /><div><span>2</span><strong>协议与资源</strong></div><i /><div><span>3</span><strong>快照确认</strong></div></div>
        <div className="form-section"><div className="form-section__title"><span>1</span><div><h3>选择老人和服务场景</h3><p>一个主档可以建立多条场景关系</p></div></div><div className="form-grid"><Field label="老人" required><select><option>林淑兰 · 78岁</option><option>蒋慧娟 · 69岁</option></select></Field><Field label="服务场景" required><select><option>居家</option><option>日间</option><option>住宿</option><option>喘息</option></select></Field><Field label="开始日期" required><input type="date" defaultValue="2026-07-18" /></Field><Field label="主要联系对象" required><select><option>林志远 · 儿子 · 主要联系人</option></select></Field></div></div>
        <div className="form-section"><div className="form-section__title"><span>2</span><div><h3>服务配置</h3><p>先选择当前目录，最后保存不可变快照</p></div></div><div className="form-grid"><Field label="负责站点"><select><option>云栖中心站</option><option>杏林社区服务点</option></select></Field><Field label="套餐"><select><option>居家安心月包 · ¥399/月</option><option>不使用套餐</option></select></Field><Field label="协议编号"><input defaultValue="XY-2026-0720" /></Field><Field label="资源（按场景）"><select><option>姑苏区 · 机构服务范围内</option></select></Field></div><div className="form-info"><ShieldCheck size={18} /><span>下一步将展示套餐、权益和价格快照，确认后再启用关系。</span></div></div>
      </Drawer>
    </>
  );
}
