/**
 * Analytics Page — real platform metrics, wired to bookingsApi.getBookingStats()
 * and usersApi.getWorkerStats() / getCustomerStats() / getWorkers().
 */
import { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Tabs,
  Tab,
  Skeleton,
  Alert,
  Paper,
  ToggleButton,
  ToggleButtonGroup,
  IconButton,
  Tooltip as MuiTooltip,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Avatar,
  Rating,
  Chip,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  CalendarMonth as CalendarMonthIcon,
  Groups as GroupsIcon,
  StarRate as StarRateIcon,
  TableChartOutlined as TableChartOutlinedIcon,
  BarChartOutlined as BarChartOutlinedIcon,
} from '@mui/icons-material';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  AreaChart,
  Area,
} from 'recharts';
import { bookingsApi, usersApi } from '../services/api';

// ---- Chart chrome (single-hue nominal data — position + label carry
// identity, so color doesn't need to; see dataviz skill, anti-patterns
// "value-ramp on nominal categories") ----
const CHART_BLUE = '#2a78d6';
const GRID_COLOR = '#e1e0d9';
const AXIS_COLOR = '#c3c2b7';
const MUTED_TEXT = '#898781';

type Period = 'day' | 'week' | 'month';

interface BookingStats {
  totalBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  pendingBookings: number;
  inProgressBookings: number;
  averageRating: number;
  totalRevenue: number;
  totalCustomers: number;
  activeWorkers: number;
  dailyBookings: { date: string; dayName: string; bookings: number }[];
  monthlyRevenue: { month: string; revenue: number }[];
  categoryDistribution: { name: string; value: number; revenue: number }[];
}

interface WorkerStats {
  total: number;
  active: number;
  pending: number;
  suspended: number;
}

interface CustomerStats {
  total: number;
  active: number;
  totalBookings: number;
  newThisMonth: number;
}

interface TopWorker {
  _id: string;
  firstName: string;
  lastName: string;
  profileImage?: string;
  rating: { average: number; count: number };
  totalJobsCompleted: number;
  status: string;
}

function formatCompact(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}K`;
  return value.toLocaleString();
}

function formatCurrency(value: number): string {
  return `Rs. ${formatCompact(value)}`;
}

function TabPanel({
  children,
  value,
  index,
}: {
  children: React.ReactNode;
  value: number;
  index: number;
}) {
  return value === index ? <Box sx={{ pt: 3 }}>{children}</Box> : null;
}

function StatTile({
  label,
  value,
  icon,
  color,
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  color: string;
}) {
  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" gap={1} mb={1}>
          <Box sx={{ color }}>{icon}</Box>
          <Typography variant="body2" color="text.secondary">
            {label}
          </Typography>
        </Box>
        <Typography variant="h4" fontWeight={600}>
          {value}
        </Typography>
      </CardContent>
    </Card>
  );
}

/** Values lead, label follows — the reader has the series, wants the number. */
function ChartTooltip({ active, payload, label, valueFormatter }: any) {
  if (!active || !payload?.length) return null;
  return (
    <Box
      sx={{
        bgcolor: 'background.paper',
        border: '1px solid rgba(11,11,11,0.10)',
        borderRadius: 1,
        px: 1.5,
        py: 1,
        boxShadow: 2,
      }}
    >
      <Typography variant="caption" color="text.secondary" display="block">
        {label}
      </Typography>
      {payload.map((p: any) => (
        <Typography key={p.dataKey} variant="body2" fontWeight={600}>
          {valueFormatter ? valueFormatter(p.value) : p.value}
        </Typography>
      ))}
    </Box>
  );
}

/** A chart with a table-view twin — toggle button swaps between them so
 * every value stays reachable without relying on hover (dataviz skill,
 * "no table view / color-only encoding" anti-pattern). */
function ChartCard({
  title,
  height = 300,
  columns,
  rows,
  children,
}: {
  title: string;
  height?: number;
  columns: string[];
  rows: (string | number)[][];
  children: React.ReactNode;
}) {
  const [showTable, setShowTable] = useState(false);

  return (
    <Box mb={3}>
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={1}>
        <Typography variant="h6">{title}</Typography>
        <MuiTooltip title={showTable ? 'Show chart' : 'Show table'}>
          <IconButton size="small" onClick={() => setShowTable((s) => !s)}>
            {showTable ? <BarChartOutlinedIcon fontSize="small" /> : <TableChartOutlinedIcon fontSize="small" />}
          </IconButton>
        </MuiTooltip>
      </Box>
      {showTable ? (
        <Table size="small">
          <TableHead>
            <TableRow>
              {columns.map((c) => (
                <TableCell key={c}>{c}</TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row, i) => (
              <TableRow key={i}>
                {row.map((cell, j) => (
                  <TableCell key={j} sx={{ fontVariantNumeric: 'tabular-nums' }}>
                    {cell}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      ) : (
        <Box sx={{ width: '100%', height }}>{children}</Box>
      )}
    </Box>
  );
}

export default function AnalyticsPage() {
  const [tab, setTab] = useState(0);
  const [period, setPeriod] = useState<Period>('month');

  const [stats, setStats] = useState<BookingStats | null>(null);
  const [workerStats, setWorkerStats] = useState<WorkerStats | null>(null);
  const [customerStats, setCustomerStats] = useState<CustomerStats | null>(null);
  const [topWorkers, setTopWorkers] = useState<TopWorker[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError('');

    bookingsApi
      .getBookingStats(period)
      .then((res) => {
        if (!cancelled) setStats(res.stats);
      })
      .catch((err) => {
        if (!cancelled) setError(err?.message ?? 'Failed to load analytics');
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [period]);

  useEffect(() => {
    let cancelled = false;

    Promise.all([usersApi.getWorkerStats(), usersApi.getCustomerStats(), usersApi.getWorkers({ page: 1, limit: 50 })])
      .then(([workerStatsRes, customerStatsRes, workersRes]) => {
        if (cancelled) return;
        setWorkerStats(workerStatsRes);
        setCustomerStats(customerStatsRes);
        const top = [...workersRes.workers]
          .sort((a, b) => (b.rating?.average ?? 0) - (a.rating?.average ?? 0))
          .slice(0, 5);
        setTopWorkers(top);
      })
      .catch(() => {
        // Worker/customer summary is supplementary — booking stats above
        // already surfaced a top-level error if the backend is down.
      });

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3} flexWrap="wrap" gap={2}>
        <Typography variant="h4" fontWeight={700}>
          Analytics
        </Typography>

        {/* Filter row — scopes every stat, chart, and table below it */}
        <ToggleButtonGroup
          size="small"
          value={period}
          exclusive
          onChange={(_, value) => value && setPeriod(value)}
        >
          <ToggleButton value="day">Today</ToggleButton>
          <ToggleButton value="week">Last 7 days</ToggleButton>
          <ToggleButton value="month">Last 30 days</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Summary Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          {loading || !stats ? (
            <Card>
              <CardContent>
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="40%" height={40} />
              </CardContent>
            </Card>
          ) : (
            <StatTile
              label="Total Revenue"
              value={formatCurrency(stats.totalRevenue)}
              icon={<TrendingUpIcon />}
              color="#4caf50"
            />
          )}
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          {loading || !stats ? (
            <Card>
              <CardContent>
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="40%" height={40} />
              </CardContent>
            </Card>
          ) : (
            <StatTile
              label="Total Bookings"
              value={stats.totalBookings.toLocaleString()}
              icon={<CalendarMonthIcon />}
              color="#2196f3"
            />
          )}
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          {loading || !stats ? (
            <Card>
              <CardContent>
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="40%" height={40} />
              </CardContent>
            </Card>
          ) : (
            <StatTile
              label="Active Workers"
              value={stats.activeWorkers.toLocaleString()}
              icon={<GroupsIcon />}
              color="#ff9800"
            />
          )}
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          {loading || !stats ? (
            <Card>
              <CardContent>
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="40%" height={40} />
              </CardContent>
            </Card>
          ) : (
            <StatTile
              label="Avg. Rating"
              value={stats.averageRating ? stats.averageRating.toFixed(1) : '—'}
              icon={<StarRateIcon />}
              color="#9c27b0"
            />
          )}
        </Grid>
      </Grid>

      {/* Tabs for different analytics views */}
      <Paper sx={{ px: 2, pb: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)}>
          <Tab label="Bookings" />
          <Tab label="Revenue" />
          <Tab label="Workers" />
          <Tab label="Customers" />
        </Tabs>

        {/* Bookings */}
        <TabPanel value={tab} index={0}>
          {loading || !stats ? (
            <>
              <Skeleton variant="rectangular" height={300} sx={{ borderRadius: 2, mb: 3 }} />
              <Skeleton variant="rectangular" height={250} sx={{ borderRadius: 2 }} />
            </>
          ) : (
            <>
              <ChartCard
                title="Booking Trends"
                columns={['Date', 'Bookings']}
                rows={stats.dailyBookings.map((d) => [d.dayName + ' ' + d.date, d.bookings])}
              >
                <ResponsiveContainer>
                  <BarChart data={stats.dailyBookings} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <CartesianGrid stroke={GRID_COLOR} vertical={false} />
                    <XAxis
                      dataKey="dayName"
                      stroke={AXIS_COLOR}
                      tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                      tickLine={false}
                    />
                    <YAxis
                      stroke={AXIS_COLOR}
                      tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                      tickLine={false}
                      allowDecimals={false}
                    />
                    <Tooltip content={<ChartTooltip />} cursor={{ fill: 'rgba(11,11,11,0.04)' }} />
                    <Bar dataKey="bookings" fill={CHART_BLUE} radius={[4, 4, 0, 0]} maxBarSize={24} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartCard>

              {stats.categoryDistribution.length === 0 ? (
                <Alert severity="info">No bookings in this period yet.</Alert>
              ) : (
                <ChartCard
                  title="Category Distribution"
                  height={Math.max(200, stats.categoryDistribution.length * 44)}
                  columns={['Category', 'Bookings']}
                  rows={stats.categoryDistribution.map((c) => [c.name, c.value])}
                >
                  <ResponsiveContainer>
                    <BarChart
                      data={[...stats.categoryDistribution].sort((a, b) => b.value - a.value)}
                      layout="vertical"
                      margin={{ top: 8, right: 24, left: 8, bottom: 0 }}
                    >
                      <CartesianGrid stroke={GRID_COLOR} horizontal={false} />
                      <XAxis
                        type="number"
                        stroke={AXIS_COLOR}
                        tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                        tickLine={false}
                        allowDecimals={false}
                      />
                      <YAxis
                        type="category"
                        dataKey="name"
                        stroke={AXIS_COLOR}
                        tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                        tickLine={false}
                        width={110}
                      />
                      <Tooltip content={<ChartTooltip />} cursor={{ fill: 'rgba(11,11,11,0.04)' }} />
                      <Bar dataKey="value" fill={CHART_BLUE} radius={[0, 4, 4, 0]} maxBarSize={20} />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartCard>
              )}
            </>
          )}
        </TabPanel>

        {/* Revenue */}
        <TabPanel value={tab} index={1}>
          {loading || !stats ? (
            <>
              <Skeleton variant="rectangular" height={300} sx={{ borderRadius: 2, mb: 3 }} />
              <Skeleton variant="rectangular" height={250} sx={{ borderRadius: 2 }} />
            </>
          ) : (
            <>
              <ChartCard
                title="Revenue Trend"
                columns={['Date', 'Revenue']}
                rows={stats.monthlyRevenue.map((r) => [r.month, formatCurrency(r.revenue)])}
              >
                <ResponsiveContainer>
                  <AreaChart data={stats.monthlyRevenue} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <CartesianGrid stroke={GRID_COLOR} vertical={false} />
                    <XAxis
                      dataKey="month"
                      stroke={AXIS_COLOR}
                      tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                      tickLine={false}
                    />
                    <YAxis
                      stroke={AXIS_COLOR}
                      tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                      tickLine={false}
                      tickFormatter={formatCompact}
                    />
                    <Tooltip content={<ChartTooltip valueFormatter={formatCurrency} />} />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke={CHART_BLUE}
                      strokeWidth={2}
                      fill={CHART_BLUE}
                      fillOpacity={0.1}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </ChartCard>

              {stats.categoryDistribution.length === 0 ? (
                <Alert severity="info">No revenue in this period yet.</Alert>
              ) : (
                <ChartCard
                  title="Revenue by Category"
                  height={Math.max(200, stats.categoryDistribution.length * 44)}
                  columns={['Category', 'Revenue']}
                  rows={stats.categoryDistribution.map((c) => [c.name, formatCurrency(c.revenue)])}
                >
                  <ResponsiveContainer>
                    <BarChart
                      data={[...stats.categoryDistribution].sort((a, b) => b.revenue - a.revenue)}
                      layout="vertical"
                      margin={{ top: 8, right: 24, left: 8, bottom: 0 }}
                    >
                      <CartesianGrid stroke={GRID_COLOR} horizontal={false} />
                      <XAxis
                        type="number"
                        stroke={AXIS_COLOR}
                        tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                        tickLine={false}
                        tickFormatter={formatCompact}
                      />
                      <YAxis
                        type="category"
                        dataKey="name"
                        stroke={AXIS_COLOR}
                        tick={{ fill: MUTED_TEXT, fontSize: 12 }}
                        tickLine={false}
                        width={110}
                      />
                      <Tooltip content={<ChartTooltip valueFormatter={formatCurrency} />} cursor={{ fill: 'rgba(11,11,11,0.04)' }} />
                      <Bar dataKey="revenue" fill={CHART_BLUE} radius={[0, 4, 4, 0]} maxBarSize={20} />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartCard>
              )}
            </>
          )}
        </TabPanel>

        {/* Workers */}
        <TabPanel value={tab} index={2}>
          <Grid container spacing={3} mb={3}>
            {(
              [
                ['Total Workers', workerStats?.total, '#2196f3'],
                ['Active', workerStats?.active, '#4caf50'],
                ['Pending Verification', workerStats?.pending, '#ff9800'],
                ['Suspended', workerStats?.suspended, '#e53935'],
              ] as [string, number | undefined, string][]
            ).map(([label, value, color]) => (
              <Grid size={{ xs: 12, sm: 6, md: 3 }} key={label}>
                {value === undefined ? (
                  <Card>
                    <CardContent>
                      <Skeleton variant="text" width="60%" />
                      <Skeleton variant="text" width="40%" height={40} />
                    </CardContent>
                  </Card>
                ) : (
                  <StatTile label={label} value={value.toLocaleString()} icon={<GroupsIcon />} color={color} />
                )}
              </Grid>
            ))}
          </Grid>

          <Typography variant="h6" gutterBottom>
            Top Workers
          </Typography>
          {topWorkers.length === 0 ? (
            <Skeleton variant="rectangular" height={200} sx={{ borderRadius: 2 }} />
          ) : (
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Worker</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Rating</TableCell>
                  <TableCell align="right">Jobs Completed</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {topWorkers.map((w) => (
                  <TableRow key={w._id}>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={1}>
                        <Avatar src={w.profileImage} sx={{ width: 28, height: 28 }}>
                          {w.firstName?.[0]}
                        </Avatar>
                        {w.firstName} {w.lastName}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={w.status.replace('_', ' ')}
                        color={w.status === 'ACTIVE' ? 'success' : 'default'}
                        variant="outlined"
                      />
                    </TableCell>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={0.5}>
                        <Rating value={w.rating?.average ?? 0} readOnly size="small" precision={0.5} />
                        <Typography variant="caption" color="text.secondary">
                          ({w.rating?.count ?? 0})
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell align="right" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                      {w.totalJobsCompleted}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </TabPanel>

        {/* Customers */}
        <TabPanel value={tab} index={3}>
          <Grid container spacing={3}>
            {(
              [
                ['Total Customers', customerStats?.total, '#2196f3'],
                ['Active', customerStats?.active, '#4caf50'],
                ['New This Month', customerStats?.newThisMonth, '#9c27b0'],
                ['Total Bookings', customerStats?.totalBookings, '#ff9800'],
              ] as [string, number | undefined, string][]
            ).map(([label, value, color]) => (
              <Grid size={{ xs: 12, sm: 6, md: 3 }} key={label}>
                {value === undefined ? (
                  <Card>
                    <CardContent>
                      <Skeleton variant="text" width="60%" />
                      <Skeleton variant="text" width="40%" height={40} />
                    </CardContent>
                  </Card>
                ) : (
                  <StatTile label={label} value={value.toLocaleString()} icon={<GroupsIcon />} color={color} />
                )}
              </Grid>
            ))}
          </Grid>
        </TabPanel>
      </Paper>
    </Box>
  );
}
