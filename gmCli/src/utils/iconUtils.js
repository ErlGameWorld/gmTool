import React from 'react';
import {
  DashboardOutlined,
  UserOutlined,
  ToolOutlined,
  SettingOutlined,
  AppstoreOutlined,
  EyeOutlined,
  SearchOutlined,
  GiftOutlined,
  ExperimentOutlined,
  BoxPlotOutlined,
  HeartOutlined,
  FileTextOutlined,
  PictureOutlined,
  LockOutlined,
  UnlockOutlined,
  PlusCircleOutlined,
  BellOutlined,
  UnorderedListOutlined,
  DeleteOutlined,
  LineChartOutlined,
  BarChartOutlined,
  SyncOutlined,
  TableOutlined,
  FormOutlined,
  CodeOutlined,
  CommentOutlined,
  ShareAltOutlined,
  WarningOutlined,
  DisconnectOutlined,
  BorderOutlined,
  SlidersOutlined,
  AppstoreAddOutlined,
  ThunderboltOutlined,
  FundOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  KeyOutlined,
  DatabaseOutlined,
  ShoppingOutlined,
  ShopOutlined,
  TagsOutlined,
  TagOutlined,
  FileOutlined,
  FolderOutlined,
  InboxOutlined,
  CarryOutOutlined,
  GoldOutlined,
  CrownOutlined,
  TrophyOutlined,
  StarOutlined,
  FireOutlined,
  BulbOutlined,
  RocketOutlined,
  CarOutlined,
  CameraOutlined,
  CloudOutlined,
  CoffeeOutlined,
  CompassOutlined,
  BankOutlined,
  WalletOutlined,
  MoneyCollectOutlined,
  SafetyOutlined,
  SafetyCertificateOutlined,
  MedicineBoxOutlined,
  BookOutlined,
  CalendarOutlined,
  ClockCircleOutlined,
  EnvironmentOutlined,
  FlagOutlined,
  HomeOutlined,
  MenuOutlined,
  ClusterOutlined,
  IdcardOutlined,
  FontSizeOutlined,
  ApartmentOutlined,
  ContainerOutlined
} from '@ant-design/icons';

/**
 * Fa 风格后端名 → antd 图标组件。IconPreview 与侧栏共用此表。
 * 新增图标时只改这里，预览页会自动出现。
 */
export const FA_ICON_ENTRIES = [
  // 分组 / 常用菜单
  { backendName: 'fa-chart-line', component: LineChartOutlined, group: '基础功能', desc: '折线/监控' },
  { backendName: 'fa-users', component: UserOutlined, group: '基础功能', desc: '用户/玩家' },
  { backendName: 'fa-cube', component: AppstoreOutlined, group: '物品管理', desc: '九宫格集合' },
  { backendName: 'fa-cogs', component: SettingOutlined, group: '基础功能', desc: '系统设置' },
  { backendName: 'fa-tools', component: ToolOutlined, group: '基础功能', desc: '工具' },
  { backendName: 'fa-box', component: BoxPlotOutlined, group: '物品管理', desc: '容器/箱' },
  { backendName: 'fa-gift', component: GiftOutlined, group: '物品管理', desc: '礼物/奖励' },
  { backendName: 'fa-server', component: DashboardOutlined, group: '基础功能', desc: '服务器' },
  { backendName: 'fa-shapes', component: BorderOutlined, group: '基础功能', desc: '形状/返回格式' },
  { backendName: 'fa-sliders-h', component: SlidersOutlined, group: '基础功能', desc: '滑块/参数' },
  { backendName: 'fa-table', component: TableOutlined, group: '基础功能', desc: '表格' },
  { backendName: 'fa-th-large', component: AppstoreAddOutlined, group: '基础功能', desc: '大宫格卡片' },
  { backendName: 'fa-th', component: AppstoreOutlined, group: '基础功能', desc: '宫格' },
  { backendName: 'fa-wpforms', component: FormOutlined, group: '基础功能', desc: '表单' },
  { backendName: 'fa-code', component: CodeOutlined, group: '基础功能', desc: '代码/JSON' },
  { backendName: 'fa-comment', component: CommentOutlined, group: '基础功能', desc: '消息' },
  { backendName: 'fa-share', component: ShareAltOutlined, group: '基础功能', desc: '跳转/分享' },
  { backendName: 'fa-exclamation-triangle', component: WarningOutlined, group: '基础功能', desc: '警告/错误' },
  { backendName: 'fa-unlink', component: DisconnectOutlined, group: '基础功能', desc: '断开/404' },
  { backendName: 'fa-keyboard', component: FontSizeOutlined, group: '基础功能', desc: '键盘/输入' },
  { backendName: 'fa-user-circle', component: IdcardOutlined, group: '基础功能', desc: '玩家详情' },
  { backendName: 'fa-user-check', component: CheckCircleOutlined, group: '基础功能', desc: '解封/校验' },
  { backendName: 'fa-user-times', component: CloseCircleOutlined, group: '基础功能', desc: '踢出' },
  { backendName: 'fa-user-lock', component: LockOutlined, group: '安全和存储', desc: '封禁' },
  { backendName: 'fa-tachometer-alt', component: FundOutlined, group: '基础功能', desc: '仪表盘' },
  { backendName: 'fa-heartbeat', component: HeartOutlined, group: '游戏物品', desc: '心跳/状态' },
  { backendName: 'fa-file-alt', component: FileTextOutlined, group: '物品管理', desc: '日志/文档' },
  { backendName: 'fa-plus-circle', component: PlusCircleOutlined, group: '基础功能', desc: '新增' },
  { backendName: 'fa-bullhorn', component: BellOutlined, group: '基础功能', desc: '公告' },
  { backendName: 'fa-bell', component: BellOutlined, group: '基础功能', desc: '告警铃' },
  { backendName: 'fa-cog', component: SettingOutlined, group: '基础功能', desc: '齿轮设置' },
  { backendName: 'fa-eye', component: EyeOutlined, group: '安全和存储', desc: '观察' },
  { backendName: 'fa-search', component: SearchOutlined, group: '基础功能', desc: '搜索' },
  { backendName: 'fa-images', component: PictureOutlined, group: '物品管理', desc: '图片' },
  { backendName: 'fa-flask', component: ExperimentOutlined, group: '安全和存储', desc: '实验' },
  { backendName: 'fa-sync', component: SyncOutlined, group: '基础功能', desc: '刷新' },
  { backendName: 'fa-list', component: UnorderedListOutlined, group: '基础功能', desc: '列表' },
  { backendName: 'fa-trash', component: DeleteOutlined, group: '基础功能', desc: '删除' },
  { backendName: 'fa-bolt', component: ThunderboltOutlined, group: '游戏物品', desc: '闪电' },
  { backendName: 'fa-chart-bar', component: BarChartOutlined, group: '物品管理', desc: '柱状图' },
  { backendName: 'fa-layer-group', component: ClusterOutlined, group: '基础功能', desc: '分组/层级' },
  { backendName: 'fa-bars', component: MenuOutlined, group: '基础功能', desc: '菜单' },
  // IconPreview 扩展
  { backendName: 'fa-database', component: DatabaseOutlined, group: '物品管理', desc: '数据库' },
  { backendName: 'fa-shopping-cart', component: ShoppingOutlined, group: '物品管理', desc: '购物车' },
  { backendName: 'fa-store', component: ShopOutlined, group: '物品管理', desc: '商店' },
  { backendName: 'fa-tags', component: TagsOutlined, group: '物品管理', desc: '多标签' },
  { backendName: 'fa-tag', component: TagOutlined, group: '物品管理', desc: '标签' },
  { backendName: 'fa-file', component: FileOutlined, group: '物品管理', desc: '文件' },
  { backendName: 'fa-folder', component: FolderOutlined, group: '物品管理', desc: '文件夹' },
  { backendName: 'fa-inbox', component: InboxOutlined, group: '物品管理', desc: '收件箱' },
  { backendName: 'fa-briefcase', component: CarryOutOutlined, group: '物品管理', desc: '公文包' },
  { backendName: 'fa-coins', component: GoldOutlined, group: '游戏物品', desc: '金币' },
  { backendName: 'fa-crown', component: CrownOutlined, group: '游戏物品', desc: '皇冠' },
  { backendName: 'fa-trophy', component: TrophyOutlined, group: '游戏物品', desc: '奖杯' },
  { backendName: 'fa-star', component: StarOutlined, group: '游戏物品', desc: '星星' },
  { backendName: 'fa-heart', component: HeartOutlined, group: '游戏物品', desc: '爱心' },
  { backendName: 'fa-fire', component: FireOutlined, group: '游戏物品', desc: '火焰' },
  { backendName: 'fa-lightbulb', component: BulbOutlined, group: '游戏物品', desc: '灯泡' },
  { backendName: 'fa-rocket', component: RocketOutlined, group: '游戏物品', desc: '火箭' },
  { backendName: 'fa-car', component: CarOutlined, group: '游戏物品', desc: '汽车' },
  { backendName: 'fa-camera', component: CameraOutlined, group: '游戏物品', desc: '相机' },
  { backendName: 'fa-cloud', component: CloudOutlined, group: '游戏物品', desc: '云' },
  { backendName: 'fa-coffee', component: CoffeeOutlined, group: '游戏物品', desc: '咖啡' },
  { backendName: 'fa-compass', component: CompassOutlined, group: '游戏物品', desc: '指南针' },
  { backendName: 'fa-university', component: BankOutlined, group: '安全和存储', desc: '银行' },
  { backendName: 'fa-wallet', component: WalletOutlined, group: '安全和存储', desc: '钱包' },
  { backendName: 'fa-money-bill-wave', component: MoneyCollectOutlined, group: '安全和存储', desc: '收钱' },
  { backendName: 'fa-shield-alt', component: SafetyOutlined, group: '安全和存储', desc: '盾牌' },
  { backendName: 'fa-lock', component: LockOutlined, group: '安全和存储', desc: '锁' },
  { backendName: 'fa-unlock', component: UnlockOutlined, group: '安全和存储', desc: '解锁' },
  { backendName: 'fa-key', component: KeyOutlined, group: '安全和存储', desc: '钥匙' },
  { backendName: 'fa-certificate', component: SafetyCertificateOutlined, group: '安全和存储', desc: '证书' },
  { backendName: 'fa-medkit', component: MedicineBoxOutlined, group: '安全和存储', desc: '药箱' },
  { backendName: 'fa-book', component: BookOutlined, group: '安全和存储', desc: '书籍' },
  { backendName: 'fa-calendar', component: CalendarOutlined, group: '安全和存储', desc: '日历' },
  { backendName: 'fa-clock', component: ClockCircleOutlined, group: '安全和存储', desc: '时钟' },
  { backendName: 'fa-globe', component: EnvironmentOutlined, group: '安全和存储', desc: '地球' },
  { backendName: 'fa-flag', component: FlagOutlined, group: '安全和存储', desc: '旗帜' },
  { backendName: 'fa-home', component: HomeOutlined, group: '安全和存储', desc: '家园' },
  { backendName: 'fa-container', component: ContainerOutlined, group: '物品管理', desc: '集装箱' }
];

const FA_ICON_MAP = Object.fromEntries(
  FA_ICON_ENTRIES.map((e) => [e.backendName, e.component])
);

const warned = new Set();

function resolveIcon(iconName, fallback, withMargin) {
  const Comp = FA_ICON_MAP[iconName];
  if (!Comp) {
    if (iconName && !warned.has(iconName)) {
      warned.add(iconName);
      console.warn(`[iconUtils] 未映射的图标: ${iconName}`);
    }
    return React.createElement(fallback, withMargin ? { style: { marginRight: 8 } } : undefined);
  }
  return React.createElement(Comp, withMargin ? { style: { marginRight: 8 } } : undefined);
}

export const getGroupIcon = (iconName) => resolveIcon(iconName, DashboardOutlined, true);

export const getMenuIcon = (iconName) => resolveIcon(iconName, ToolOutlined, true);

export const getIconComponent = (iconName) => FA_ICON_MAP[iconName] || null;

export const buildIconPreviewGroups = () => {
  const order = ['物品管理', '游戏物品', '安全和存储', '基础功能'];
  const byGroup = {};
  for (const e of FA_ICON_ENTRIES) {
    const g = e.group || '基础功能';
    if (!byGroup[g]) byGroup[g] = [];
    byGroup[g].push({
      name: e.component.displayName || e.component.name || e.backendName,
      backendName: e.backendName,
      component: e.component,
      desc: e.desc || e.backendName
    });
  }
  return order
    .filter((t) => byGroup[t]?.length)
    .map((title) => ({ title: `${title}相关图标`, icons: byGroup[title] }));
};
