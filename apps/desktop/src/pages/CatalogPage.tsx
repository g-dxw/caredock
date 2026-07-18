import { useMemo, useState } from "react";
import { Box, CircleDollarSign, Filter, Layers3, PackageCheck, Plus, Sparkles } from "lucide-react";
import { chargeItems, packages, serviceItems } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, SceneBadge, SearchField, SectionCard, Segmented, StatCard } from "../components/Ui";

type CatalogTab = "services" | "charges" | "packages";

export function CatalogPage({ initialTab = "services" }: { initialTab?: CatalogTab }) {
  const [tab, setTab] = useState<CatalogTab>(initialTab);
  const [query, setQuery] = useState("");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const tabs = [
    { value: "services" as const, label: "服务项目", count: serviceItems.length },
    { value: "charges" as const, label: "收费与价格", count: chargeItems.length },
    { value: "packages" as const, label: "套餐", count: packages.length },
  ];
  const title = tab === "services" ? "新增服务项目" : tab === "charges" ? "新增收费项目" : "新建套餐";
  const filteredServices = useMemo(() => serviceItems.filter((item) => `${item.name}${item.code}${item.category}`.includes(query)), [query]);

  return (
    <>
      <PageHeader eyebrow="服务配置 / 服务目录与定价" title="服务目录与定价" description="服务项目说明“做什么”，收费项目说明“收什么”，套餐组合服务与额度。" actions={<Button onClick={() => setDrawerOpen(true)}><Plus size={16} />{title}</Button>} />
      <div className="stats-grid stats-grid--4">
        <StatCard label="已启用服务项目" value="5" helper="1 项草稿" icon={<Box size={19} />} />
        <StatCard label="收费项目" value="5" helper="2 项为非服务收费" icon={<CircleDollarSign size={19} />} tone="blue" />
        <StatCard label="在售套餐" value="3" helper="覆盖居家、日间、喘息" icon={<PackageCheck size={19} />} tone="violet" />
        <StatCard label="待完善定价" value="1" helper="陪诊服务尚未发布" icon={<Sparkles size={19} />} tone="amber" />
      </div>

      <SectionCard className="flush-card">
        <div className="catalog-tabs"><Segmented items={tabs} value={tab} onChange={(value) => { setTab(value); setQuery(""); }} /><div className="catalog-principle"><Layers3 size={16} />目录、计价和套餐保持三层分离</div></div>
        <div className="table-toolbar"><div className="table-toolbar__left"><SearchField value={query} onChange={setQuery} placeholder={`搜索${tabs.find((item) => item.value === tab)?.label}`} /><Button variant="secondary" size="sm"><Filter size={15} />筛选</Button></div><span className="result-count">当前 {tab === "services" ? filteredServices.length : tab === "charges" ? chargeItems.length : packages.length} 条</span></div>

        {tab === "services" && <div className="data-table-wrap"><table className="data-table"><thead><tr><th>服务项目</th><th>分类</th><th>适用场景</th><th>标准时长</th><th>凭证建议</th><th>参考价格</th><th>状态</th><th /></tr></thead><tbody>{filteredServices.map((service) => <tr key={service.id}><td><div className="stacked-text"><strong>{service.name}</strong><small>{service.code}</small></div></td><td>{service.category}</td><td><div className="badge-row">{service.scenes.map((scene) => <SceneBadge scene={scene} key={scene} />)}</div></td><td>{service.duration}</td><td>{service.evidence}</td><td><strong>{service.price}</strong></td><td><Badge tone={service.status === "启用" ? "green" : "gray"}>{service.status}</Badge></td><td><button className="table-link">编辑</button></td></tr>)}</tbody></table></div>}

        {tab === "charges" && <div className="data-table-wrap"><table className="data-table"><thead><tr><th>收费项目</th><th>计价单位</th><th>关联服务</th><th>价格范围</th><th>当前有效价格</th><th>状态</th><th /></tr></thead><tbody>{chargeItems.map((charge) => <tr key={charge.code}><td><div className="stacked-text"><strong>{charge.name}</strong><small>{charge.code}</small></div></td><td>{charge.unit}</td><td>{charge.linkedService === "—" ? <span className="muted">非服务收费</span> : charge.linkedService}</td><td>{charge.priceScope}</td><td><strong>{charge.currentPrice}</strong></td><td><Badge tone="green">{charge.status}</Badge></td><td><button className="table-link">价格版本</button></td></tr>)}</tbody></table><div className="table-footnote"><CircleDollarSign size={16} /><span>收费项目可以独立存在。床位费、餐费、管理费不需要强行关联服务项目。</span></div></div>}

        {tab === "packages" && <div className="package-grid">{packages.map((item) => <article className="package-card" key={item.id}><div className="package-card__header"><div className="package-icon"><PackageCheck size={20} /></div><Badge tone="green">{item.status}</Badge></div><h3>{item.name}</h3><p>{item.code} · {item.cycle}</p><div className="package-price"><strong>{item.price}</strong><span>/ {item.cycle}</span></div><dl><div><dt>适用场景</dt><dd><SceneBadge scene={item.scene} /></dd></div><div><dt>服务构成</dt><dd>{item.services}</dd></div><div><dt>核心额度</dt><dd>{item.quota}</dd></div><div><dt>使用人数</dt><dd>{item.users} 人</dd></div></dl><Button variant="secondary" className="full-width">查看套餐版本</Button></article>)}</div>}
      </SectionCard>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title={title} description={tab === "services" ? "服务项目保持原子颗粒度，可跨场景复用。" : tab === "charges" ? "收费项目与金额版本分离，保存后再配置适用价格。" : "套餐从现有服务项目中选择，不自由录入另一套名称。"}>
        {tab === "services" && <><div className="form-section"><div className="form-section__title"><span>1</span><div><h3>项目定义</h3><p>明确服务“做什么”</p></div></div><div className="form-grid"><Field label="服务名称" required><input placeholder="例如：陪同散步" /></Field><Field label="项目编码" required><input defaultValue="SH-007" /></Field><Field label="服务分类"><select><option>生活照料</option><option>居家支持</option><option>健康管理</option><option>文娱社工</option></select></Field><Field label="标准时长"><div className="input-group"><input type="number" defaultValue="30" /><span>分钟</span></div></Field></div></div><div className="form-section"><div className="form-section__title"><span>2</span><div><h3>场景与服务证据</h3><p>资格和凭证为可覆盖提示</p></div></div><div className="check-card-grid">{["居家", "日间", "住宿", "喘息"].map((item, index) => <label className="check-card" key={item}><input type="checkbox" defaultChecked={index < 2} /><span><strong>{item}</strong><small>允许在该场景使用</small></span></label>)}</div><div className="form-grid form-grid--spaced"><Field label="建议服务资格"><input placeholder="例如：养老护理员（初级）" /></Field><Field label="建议留存凭证"><select><option>服务记录</option><option>前后照片</option><option>签收记录</option><option>指标记录</option></select></Field></div></div></>}
        {tab === "charges" && <><div className="form-section"><div className="form-section__title"><span>1</span><div><h3>收费项目</h3><p>先定义收什么，不在这里覆盖历史价格</p></div></div><div className="form-grid"><Field label="收费名称" required><input placeholder="例如：陪诊服务费" /></Field><Field label="收费编码" required><input defaultValue="FEE-006" /></Field><Field label="计价单位"><select><option>次</option><option>小时</option><option>天</option><option>月</option></select></Field><Field label="关联服务（可选）"><select><option>不关联服务</option>{serviceItems.map((item) => <option key={item.id}>{item.name}</option>)}</select></Field></div></div><div className="form-section"><div className="form-section__title"><span>2</span><div><h3>首个价格版本</h3><p>尚未定价、明确免费和正价是三种不同状态</p></div></div><div className="form-grid"><Field label="适用范围"><select><option>全机构</option><option>指定场景</option><option>指定站点</option></select></Field><Field label="金额（元）"><input type="number" placeholder="留空表示尚未定价" /></Field><Field label="生效日期"><input type="date" defaultValue="2026-07-18" /></Field><Field label="版本状态"><select><option>草稿</option><option>正式</option></select></Field></div></div></>}
        {tab === "packages" && <><div className="form-section"><div className="form-section__title"><span>1</span><div><h3>套餐基本信息</h3><p>名称稳定，价格和权益按版本保存</p></div></div><div className="form-grid"><Field label="套餐名称" required><input placeholder="例如：居家关怀月包" /></Field><Field label="套餐编码" required><input defaultValue="PKG-HOME-02" /></Field><Field label="适用场景"><select><option>居家</option><option>日间</option><option>住宿</option><option>喘息</option></select></Field><Field label="计费周期"><select><option>自然月</option><option>固定天数</option><option>一次性</option></select></Field><Field label="套餐价格（元）"><input type="number" defaultValue="499" /></Field></div></div><div className="form-section"><div className="form-section__title"><span>2</span><div><h3>服务权益</h3><p>从服务项目目录选择并设置额度</p></div></div><div className="entitlement-editor">{serviceItems.slice(0, 3).map((item, index) => <label key={item.id}><input type="checkbox" defaultChecked={index < 2} /><span><strong>{item.name}</strong><small>{item.scenes.join(" / ")}</small></span><select defaultValue={index === 0 ? "fixed" : "unlimited"}><option value="fixed">固定额度</option><option value="unlimited">不限次</option></select><input type="number" defaultValue={index === 0 ? 4 : undefined} placeholder="次数" /></label>)}</div></div></>}
      </Drawer>
    </>
  );
}
