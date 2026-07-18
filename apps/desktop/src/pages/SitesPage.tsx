import { useState } from "react";
import { BedDouble, Building, ChevronRight, CircleParking, Map, Plus, Route, Users } from "lucide-react";
import { sites, spaces } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, Progress, SceneBadge, StatCard } from "../components/Ui";

export function SitesPage() {
  const [selectedId, setSelectedId] = useState<string>(sites[0].id);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const selected = sites.find((site) => site.id === selectedId) ?? sites[0];
  const occupancy = selected.formalBeds ? Math.round((selected.occupiedBeds / selected.formalBeds) * 100) : 0;

  return (
    <>
      <PageHeader eyebrow="基础配置 / 场地与资源" title="场地与资源" description="按真实经营地址管理站点、空间、床位、日间容量和居家服务范围。" actions={<Button onClick={() => setDrawerOpen(true)}><Plus size={16} />新增站点</Button>} />
      <div className="stats-grid stats-grid--4">
        <StatCard label="服务站点" value="2" helper="均处于运营中" icon={<Building size={19} />} />
        <StatCard label="正式床位" value="12" helper="当前入住 9 张" icon={<BedDouble size={19} />} tone="violet" />
        <StatCard label="日间总容量" value="32" helper="中心站 20 · 社区点 12" icon={<Users size={19} />} tone="blue" />
        <StatCard label="居家覆盖区域" value="2" helper="姑苏区、虎丘区" icon={<Route size={19} />} tone="amber" />
      </div>

      <div className="master-detail">
        <aside className="master-list">
          <div className="master-list__header"><div><strong>服务站点</strong><span>{sites.length} 个</span></div><button type="button"><Plus size={16} /></button></div>
          {sites.map((site) => (
            <button type="button" key={site.id} className={`master-item ${selectedId === site.id ? "is-active" : ""}`} onClick={() => setSelectedId(site.id)}>
              <div className="master-item__icon"><Building size={19} /></div>
              <div className="master-item__body"><strong>{site.name}</strong><span>{site.type}</span><small>{site.address}</small></div>
              <ChevronRight size={16} />
            </button>
          ))}
          <div className="master-list__tip"><Map size={17} /><span>一个机构可管理多个真实经营站点，不等同于多机构SaaS。</span></div>
        </aside>

        <div className="detail-pane">
          <div className="detail-pane__header">
            <div><div className="title-with-status"><h2>{selected.name}</h2><Badge tone="green">{selected.status}</Badge></div><p>{selected.code} · {selected.type} · {selected.address}</p><div className="badge-row">{selected.scenes.map((scene) => <SceneBadge scene={scene} key={scene} />)}</div></div>
            <Button variant="secondary">编辑站点</Button>
          </div>
          <div className="resource-summary">
            <div><span>空间节点</span><strong>{selected.spaces}</strong><small>房间与公共区域</small></div>
            <div><span>正式床位</span><strong>{selected.formalBeds || "—"}</strong><small>{selected.formalBeds ? `空闲 ${selected.formalBeds - selected.occupiedBeds} 张` : "未经营住宿"}</small></div>
            <div><span>日间容量</span><strong>{selected.dayCapacity}</strong><small>按区域容量管理</small></div>
            <div><span>居家范围</span><strong>{selected.homeDistricts.length}</strong><small>{selected.homeDistricts.join("、")}</small></div>
          </div>
          {selected.formalBeds > 0 && <div className="occupancy-line"><div><strong>床位使用率</strong><span>{selected.occupiedBeds}/{selected.formalBeds} 张</span></div><Progress value={occupancy} label={`${occupancy}%`} /></div>}

          <div className="pane-section-heading"><div><h3>空间与资源</h3><p>喘息共用床位时只增加用途，不复制物理床位。</p></div><Button size="sm" variant="secondary"><Plus size={15} />添加空间</Button></div>
          <div className="data-table-wrap">
            <table className="data-table">
              <thead><tr><th>空间名称</th><th>类型</th><th>容量</th><th>当前使用</th><th>状态</th><th /></tr></thead>
              <tbody>{spaces.slice(0, selected.id === "site-1" ? spaces.length : 2).map((space) => <tr key={space.name}><td><strong>{space.name}</strong></td><td>{space.type}</td><td>{space.capacity}</td><td>{space.usage}</td><td><Badge tone={space.status === "正常" ? "green" : "amber"}>{space.status}</Badge></td><td><button className="table-link" type="button">查看</button></td></tr>)}</tbody>
            </table>
          </div>
          <div className="site-panels">
            <div><CircleParking size={19} /><span><strong>日间休息位采用按需编号</strong><small>当前按区域容量管理；需要固定安排或维修时再建立具体位置。</small></span><Badge tone="blue">精细模式未开启</Badge></div>
            <div><Route size={19} /><span><strong>居家服务区域</strong><small>行政区划：{selected.homeDistricts.join("、")} · 同时保留文字边界说明</small></span><button type="button">维护范围</button></div>
          </div>
        </div>
      </div>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title="新增服务站点" description="建立一个真实经营地址及其可提供的服务场景。">
        <div className="form-section">
          <div className="form-section__title"><span>1</span><div><h3>站点基本信息</h3><p>站点不是独立机构，不单独注册账号</p></div></div>
          <div className="form-grid"><Field label="站点名称" required><input placeholder="例如：城南社区服务点" /></Field><Field label="站点编码" required><input defaultValue="SITE-003" /></Field><Field label="站点类型"><select><option>综合服务站</option><option>社区服务点</option><option>住宿服务点</option></select></Field><Field label="联系电话"><input placeholder="请输入站点联系电话" /></Field><Field label="实际经营地址" required><input placeholder="省 / 市 / 区 / 详细地址" /></Field></div>
        </div>
        <div className="form-section"><div className="form-section__title"><span>2</span><div><h3>服务场景</h3><p>可多选，之后仍可修改</p></div></div><div className="check-card-grid">{["居家上门", "日间照料", "集中住宿", "喘息服务"].map((item, index) => <label className="check-card" key={item}><input type="checkbox" defaultChecked={index < 2} /><span><strong>{item}</strong><small>启用对应场地和资源配置</small></span></label>)}</div></div>
      </Drawer>
    </>
  );
}
