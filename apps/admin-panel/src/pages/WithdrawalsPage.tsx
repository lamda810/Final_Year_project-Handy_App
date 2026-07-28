import { useState } from 'react';
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
  Chip,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  Tabs,
  Tab,
  Alert,
} from '@mui/material';
import {
  Visibility as ViewIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Payments as PaidIcon,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { withdrawalsApi } from '../services';

interface Withdrawal {
  _id: string;
  worker: {
    _id: string;
    firstName: string;
    lastName: string;
    phone: string;
  };
  amount: number;
  bankDetails: {
    accountTitle: string;
    accountNumber: string;
    bankName: string;
  };
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'PAID';
  adminNotes?: string;
  createdAt: string;
  updatedAt: string;
}

const STATUS_TABS = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'PAID'] as const;

const getStatusColor = (status: string) => {
  switch (status) {
    case 'PAID':
      return 'success';
    case 'APPROVED':
      return 'info';
    case 'PENDING':
      return 'warning';
    case 'REJECTED':
      return 'error';
    default:
      return 'default';
  }
};

// Only these transitions are allowed server-side — determines which action
// buttons make sense for a given request's current status.
const nextStatusesFor = (status: Withdrawal['status']): Array<'APPROVED' | 'REJECTED' | 'PAID'> => {
  if (status === 'PENDING') return ['APPROVED', 'REJECTED'];
  if (status === 'APPROVED') return ['PAID', 'REJECTED'];
  return [];
};

export default function WithdrawalsPage() {
  const queryClient = useQueryClient();
  const [tabValue, setTabValue] = useState(0);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [selectedWithdrawal, setSelectedWithdrawal] = useState<Withdrawal | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [reviewDialogOpen, setReviewDialogOpen] = useState(false);
  const [reviewTarget, setReviewTarget] = useState<'APPROVED' | 'REJECTED' | 'PAID' | null>(null);
  const [notes, setNotes] = useState('');
  const [reviewError, setReviewError] = useState<string | null>(null);

  const statusFilter = STATUS_TABS[tabValue] === 'ALL' ? undefined : STATUS_TABS[tabValue];

  const { data: withdrawalsData, isLoading, refetch } = useQuery({
    queryKey: ['withdrawals', tabValue, page, rowsPerPage],
    queryFn: () => withdrawalsApi.getWithdrawals({ page: page + 1, limit: rowsPerPage, status: statusFilter }),
  });

  const { data: statsData } = useQuery({
    queryKey: ['withdrawal-stats'],
    queryFn: () => withdrawalsApi.getStats(),
  });

  const reviewMutation = useMutation({
    mutationFn: ({ id, status, notes }: { id: string; status: 'APPROVED' | 'REJECTED' | 'PAID'; notes: string }) =>
      withdrawalsApi.reviewWithdrawal(id, { status, notes: notes || undefined }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['withdrawals'] });
      queryClient.invalidateQueries({ queryKey: ['withdrawal-stats'] });
      setReviewDialogOpen(false);
      setSelectedWithdrawal(null);
      setReviewTarget(null);
      setNotes('');
      setReviewError(null);
    },
    onError: (error: unknown) => {
      setReviewError(error instanceof Error ? error.message : 'Failed to update withdrawal. Please try again.');
    },
  });

  const withdrawals = withdrawalsData?.withdrawals ?? [];
  const total = withdrawalsData?.total ?? 0;
  const stats = statsData?.stats;

  const handleOpenView = (withdrawal: Withdrawal) => {
    setSelectedWithdrawal(withdrawal);
    setViewDialogOpen(true);
  };

  const handleOpenReview = (withdrawal: Withdrawal, target: 'APPROVED' | 'REJECTED' | 'PAID') => {
    setSelectedWithdrawal(withdrawal);
    setReviewTarget(target);
    setNotes('');
    setReviewError(null);
    setReviewDialogOpen(true);
  };

  const handleConfirmReview = () => {
    if (!selectedWithdrawal || !reviewTarget) return;
    reviewMutation.mutate({ id: selectedWithdrawal._id, status: reviewTarget, notes });
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" fontWeight={600}>
          Withdrawal Requests
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Review and process worker payout requests
        </Typography>
      </Box>

      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="warning.main">
                {stats?.pending ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Pending Review
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="info.main">
                {stats?.approved ?? 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Approved (Awaiting Payout)
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="warning.main">
                Rs. {(stats?.pendingAmount ?? 0).toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Reserved (Pending + Approved)
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="h4" fontWeight={600} color="success.main">
                Rs. {(stats?.paidAmount ?? 0).toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Paid Out
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card>
        <CardContent>
          <Tabs
            value={tabValue}
            onChange={(_e, newValue) => {
              setTabValue(newValue);
              setPage(0);
            }}
            sx={{ mb: 2 }}
          >
            <Tab label="All" />
            <Tab label="Pending" />
            <Tab label="Approved" />
            <Tab label="Rejected" />
            <Tab label="Paid" />
          </Tabs>

          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Worker</TableCell>
                  <TableCell>Amount</TableCell>
                  <TableCell>Bank Details</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Requested</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center">
                      Loading…
                    </TableCell>
                  </TableRow>
                ) : withdrawals.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center">
                      No withdrawal requests found
                    </TableCell>
                  </TableRow>
                ) : (
                  withdrawals.map((withdrawal: Withdrawal) => (
                    <TableRow key={withdrawal._id} hover>
                      <TableCell>
                        <Typography variant="body2" fontWeight={600}>
                          {withdrawal.worker.firstName} {withdrawal.worker.lastName}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {withdrawal.worker.phone}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight={600}>
                          Rs. {withdrawal.amount.toLocaleString()}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{withdrawal.bankDetails.bankName}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {withdrawal.bankDetails.accountNumber}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={withdrawal.status}
                          size="small"
                          color={getStatusColor(withdrawal.status) as 'success' | 'warning' | 'error' | 'info' | 'default'}
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {new Date(withdrawal.createdAt).toLocaleDateString()}
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <IconButton size="small" onClick={() => handleOpenView(withdrawal)}>
                          <ViewIcon fontSize="small" />
                        </IconButton>
                        {nextStatusesFor(withdrawal.status).map((target) => (
                          <IconButton
                            key={target}
                            size="small"
                            color={target === 'REJECTED' ? 'error' : 'success'}
                            onClick={() => handleOpenReview(withdrawal, target)}
                            title={
                              target === 'APPROVED' ? 'Approve' : target === 'PAID' ? 'Mark as Paid' : 'Reject'
                            }
                          >
                            {target === 'APPROVED' && <ApproveIcon fontSize="small" />}
                            {target === 'PAID' && <PaidIcon fontSize="small" />}
                            {target === 'REJECTED' && <RejectIcon fontSize="small" />}
                          </IconButton>
                        ))}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>

          <TablePagination
            component="div"
            count={total}
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

      {/* View Dialog */}
      <Dialog open={viewDialogOpen} onClose={() => setViewDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Withdrawal Request Details</DialogTitle>
        <DialogContent>
          {selectedWithdrawal && (
            <Box sx={{ mt: 1 }}>
              <Typography variant="subtitle2" color="text.secondary">
                Worker
              </Typography>
              <Typography variant="body1" sx={{ mb: 2 }}>
                {selectedWithdrawal.worker.firstName} {selectedWithdrawal.worker.lastName} (
                {selectedWithdrawal.worker.phone})
              </Typography>

              <Typography variant="subtitle2" color="text.secondary">
                Amount
              </Typography>
              <Typography variant="body1" sx={{ mb: 2 }}>
                Rs. {selectedWithdrawal.amount.toLocaleString()}
              </Typography>

              <Typography variant="subtitle2" color="text.secondary">
                Bank Details
              </Typography>
              <Typography variant="body2">{selectedWithdrawal.bankDetails.accountTitle}</Typography>
              <Typography variant="body2">{selectedWithdrawal.bankDetails.bankName}</Typography>
              <Typography variant="body2" sx={{ mb: 2 }}>
                {selectedWithdrawal.bankDetails.accountNumber}
              </Typography>

              <Typography variant="subtitle2" color="text.secondary">
                Status
              </Typography>
              <Chip
                label={selectedWithdrawal.status}
                size="small"
                color={getStatusColor(selectedWithdrawal.status) as 'success' | 'warning' | 'error' | 'info' | 'default'}
                sx={{ mb: 2 }}
              />

              {selectedWithdrawal.adminNotes && (
                <>
                  <Typography variant="subtitle2" color="text.secondary">
                    Admin Notes
                  </Typography>
                  <Typography variant="body2">{selectedWithdrawal.adminNotes}</Typography>
                </>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Review Dialog */}
      <Dialog open={reviewDialogOpen} onClose={() => setReviewDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {reviewTarget === 'APPROVED' && 'Approve Withdrawal'}
          {reviewTarget === 'REJECTED' && 'Reject Withdrawal'}
          {reviewTarget === 'PAID' && 'Mark Withdrawal as Paid'}
        </DialogTitle>
        <DialogContent>
          {selectedWithdrawal && (
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Rs. {selectedWithdrawal.amount.toLocaleString()} for {selectedWithdrawal.worker.firstName}{' '}
              {selectedWithdrawal.worker.lastName} — {selectedWithdrawal.bankDetails.bankName} (
              {selectedWithdrawal.bankDetails.accountNumber})
            </Typography>
          )}
          {reviewError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {reviewError}
            </Alert>
          )}
          <TextField
            label="Notes (optional)"
            placeholder="e.g. Transferred via HBL online banking, ref #12345"
            multiline
            minRows={2}
            fullWidth
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setReviewDialogOpen(false)} disabled={reviewMutation.isPending}>
            Cancel
          </Button>
          <Button
            onClick={handleConfirmReview}
            variant="contained"
            color={reviewTarget === 'REJECTED' ? 'error' : 'success'}
            disabled={reviewMutation.isPending}
          >
            Confirm
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
