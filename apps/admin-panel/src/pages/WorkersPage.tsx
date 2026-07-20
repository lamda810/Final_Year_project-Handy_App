import { useState } from 'react';
import { exportToCsv, workerColumns } from '../utils/exportCsv';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Avatar,
  Chip,
  IconButton,
  TextField,
  InputAdornment,
  Button,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Tabs,
  Tab,
  Rating,
  Grid,
} from '@mui/material';
import {
  Search as SearchIcon,
  MoreVert as MoreVertIcon,
  FilterList as FilterIcon,
  Visibility as ViewIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Block as BlockIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { usersApi } from '../services';

interface Worker {
  _id: string;
  firstName: string;
  lastName: string;
  profileImage?: string;
  phone: string;
  cnic: string;
  cnicVerified: boolean;
  skills: Array<{
    category: string;
    experience: number;
    hourlyRate: number;
    isVerified: boolean;
  }>;
  rating: {
    average: number;
    count: number;
  };
  trustScore: number;
  totalJobsCompleted: number;
  status: 'PENDING_VERIFICATION' | 'ACTIVE' | 'SUSPENDED' | 'INACTIVE';
  createdAt: string;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div hidden={value !== index} {...other}>
      {value === index && <Box sx={{ pt: 2 }}>{children}</Box>}
    </div>
  );
}

export default function WorkersPage() {
  const [tabValue, setTabValue] = useState(0);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchQuery, setSearchQuery] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedWorker, setSelectedWorker] = useState<Worker | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [verifyDialogOpen, setVerifyDialogOpen] = useState(false);

  const { data: workersData, isLoading, refetch } = useQuery({
    queryKey: ['workers', tabValue, page, rowsPerPage, searchQuery],
    queryFn: () => usersApi.getWorkers({
      page: page + 1,
      limit: rowsPerPage,
      search: searchQuery,
      status: tabValue === 1 ? 'PENDING_VERIFICATION' : undefined,
    }),
    select: (res) => res,
  });

  const { data: workerStats } = useQuery({
    queryKey: ['worker-stats'],
    queryFn: () => usersApi.getWorkerStats(),
  });

  const workers = workersData?.workers || [];
  const totalWorkers = workersData?.total || 0;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE':
        return 'success';
      case 'PENDING_VERIFICATION':
        return 'warning';
      case 'SUSPENDED':
        return 'error';
      default:
        return 'default';
    }
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, worker: Worker) => {
    setAnchorEl(event.currentTarget);
    setSelectedWorker(worker);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleViewWorker = () => {
    setViewDialogOpen(true);
    handleMenuClose();
  };

  const handleVerifyWorker = async (approve: boolean) => {
    if (selectedWorker) {
      try {
        await usersApi.verifyWorker(selectedWorker._id, {
          status: approve ? 'ACTIVE' : 'REJECTED',
          notes: approve ? 'Approved by admin' : 'Rejected by admin',
        });
        refetch();
      } catch (error) {
        console.error('Failed to verify worker:', error);
      }
    }
    setVerifyDialogOpen(false);
    setSelectedWorker(null);
  };

  const filteredWorkers = workers.filter((worker) => {
    if (tabValue === 1) return worker.status === 'PENDING_VERIFICATION';
    if (tabValue === 2) return worker.status === 'ACTIVE';
    if (tabValue === 3) return worker.status === 'SUSPENDED';
    return true;
  });

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight={600}>
            Workers Management
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage and verify service workers
          </Typography>
        </Box>
        <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => exportToCsv('workers', workerColumns, filteredWorkers)}>
          Export
        </Button>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="primary">
                {workerStats?.total ?? totalWorkers}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Workers
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="warning.main">
                {workerStats?.pending ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Pending Verification
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="success.main">
                {workerStats?.active ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Active Workers
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="error.main">
                {workerStats?.suspended ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Suspended
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Main Card */}
      <Card>
        <CardContent>
          {/* Tabs */}
          <Tabs value={tabValue} onChange={(_e, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
            <Tab label="All Workers" />
            <Tab label="Pending Verification" />
            <Tab label="Active" />
            <Tab label="Suspended" />
          </Tabs>

          {/* Search & Filter */}
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <TextField
              placeholder="Search workers..."
              size="small"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ width: 300 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
            <Button variant="outlined" startIcon={<FilterIcon />}>
              Filters
            </Button>
          </Box>

          {/* Table */}
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Worker</TableCell>
                  <TableCell>Phone / CNIC</TableCell>
                  <TableCell>Skills</TableCell>
                  <TableCell>Rating</TableCell>
                  <TableCell>Trust Score</TableCell>
                  <TableCell>Jobs</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredWorkers.map((worker) => (
                  <TableRow key={worker._id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar src={worker.profileImage}>
                          {worker.firstName[0]}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" fontWeight={600}>
                            {worker.firstName} {worker.lastName}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            Joined {new Date(worker.createdAt).toLocaleDateString()}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{worker.phone}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        {worker.cnic}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {worker.skills.slice(0, 2).map((skill: Worker['skills'][number], idx: number) => (
                          <Chip
                            key={idx}
                            label={skill.category}
                            size="small"
                            variant="outlined"
                          />
                        ))}
                        {worker.skills.length > 2 && (
                          <Chip
                            label={`+${worker.skills.length - 2}`}
                            size="small"
                            variant="outlined"
                          />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <Rating value={worker.rating.average} readOnly size="small" precision={0.1} />
                        <Typography variant="caption">
                          ({worker.rating.count})
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Box
                          sx={{
                            width: 40,
                            height: 8,
                            borderRadius: 1,
                            backgroundColor: 'grey.200',
                            overflow: 'hidden',
                          }}
                        >
                          <Box
                            sx={{
                              width: `${worker.trustScore}%`,
                              height: '100%',
                              backgroundColor:
                                worker.trustScore >= 80
                                  ? 'success.main'
                                  : worker.trustScore >= 60
                                  ? 'warning.main'
                                  : 'error.main',
                            }}
                          />
                        </Box>
                        <Typography variant="caption">{worker.trustScore}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>{worker.totalJobsCompleted}</TableCell>
                    <TableCell>
                      <Chip
                        label={worker.status.replace('_', ' ')}
                        size="small"
                        color={getStatusColor(worker.status) as 'success' | 'warning' | 'error' | 'default'}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <IconButton onClick={(e) => handleMenuOpen(e, worker)}>
                        <MoreVertIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          <TablePagination
            component="div"
            count={totalWorkers}
            page={page}
            onPageChange={(_e, newPage) => setPage(newPage)}
            rowsPerPage={rowsPerPage}
            onRowsPerPageChange={(e) => {
              setRowsPerPage(parseInt(e.target.value, 10));
              setPage(0);
            }}
          />
        </CardContent>
      </Card>

      {/* Actions Menu */}
      <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={handleMenuClose}>
        <MenuItem onClick={handleViewWorker}>
          <ViewIcon sx={{ mr: 1 }} fontSize="small" />
          View Details
        </MenuItem>
        {selectedWorker?.status === 'PENDING_VERIFICATION' && (
          <>
            <MenuItem onClick={() => { setVerifyDialogOpen(true); handleMenuClose(); }}>
              <ApproveIcon sx={{ mr: 1 }} fontSize="small" color="success" />
              Approve
            </MenuItem>
            <MenuItem onClick={() => { setVerifyDialogOpen(true); handleMenuClose(); }}>
              <RejectIcon sx={{ mr: 1 }} fontSize="small" color="error" />
              Reject
            </MenuItem>
          </>
        )}
        {selectedWorker?.status === 'ACTIVE' && (
          <MenuItem onClick={handleMenuClose}>
            <BlockIcon sx={{ mr: 1 }} fontSize="small" color="error" />
            Suspend
          </MenuItem>
        )}
      </Menu>

      {/* View Worker Dialog */}
      <Dialog open={viewDialogOpen} onClose={() => setViewDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Worker Details</DialogTitle>
        <DialogContent>
          {selectedWorker && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid size={{ xs: 12, md: 4 }}>
                <Box sx={{ textAlign: 'center' }}>
                  <Avatar
                    src={selectedWorker.profileImage}
                    sx={{ width: 120, height: 120, mx: 'auto', mb: 2 }}
                  >
                    {selectedWorker.firstName[0]}
                  </Avatar>
                  <Typography variant="h6">
                    {selectedWorker.firstName} {selectedWorker.lastName}
                  </Typography>
                  <Chip
                    label={selectedWorker.status.replace('_', ' ')}
                    color={getStatusColor(selectedWorker.status) as 'success' | 'warning' | 'error' | 'default'}
                    sx={{ mt: 1 }}
                  />
                </Box>
              </Grid>
              <Grid size={{ xs: 12, md: 8 }}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Contact Information
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  Phone: {selectedWorker.phone}
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  CNIC: {selectedWorker.cnic} {selectedWorker.cnicVerified && '✓ Verified'}
                </Typography>

                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ mt: 3 }}>
                  Skills
                </Typography>
                {selectedWorker.skills.map((skill, idx) => (
                  <Box key={idx} sx={{ mb: 1 }}>
                    <Typography variant="body2">
                      {skill.category} - {skill.experience} years experience
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Hourly Rate: Rs. {skill.hourlyRate}
                    </Typography>
                  </Box>
                ))}

                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ mt: 3 }}>
                  Performance
                </Typography>
                <Typography variant="body2">
                  Rating: {selectedWorker.rating.average}/5 ({selectedWorker.rating.count} reviews)
                </Typography>
                <Typography variant="body2">
                  Trust Score: {selectedWorker.trustScore}/100
                </Typography>
                <Typography variant="body2">
                  Jobs Completed: {selectedWorker.totalJobsCompleted}
                </Typography>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Verify Dialog */}
      <Dialog open={verifyDialogOpen} onClose={() => setVerifyDialogOpen(false)}>
        <DialogTitle>Verify Worker</DialogTitle>
        <DialogContent>
          <Typography>
            Do you want to approve or reject this worker's registration?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setVerifyDialogOpen(false)}>Cancel</Button>
          <Button onClick={() => handleVerifyWorker(false)} color="error">
            Reject
          </Button>
          <Button onClick={() => handleVerifyWorker(true)} variant="contained" color="success">
            Approve
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
