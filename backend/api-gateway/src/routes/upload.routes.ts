import { Router, Request, Response } from 'express';
import multer from 'multer';
import { randomUUID } from 'crypto';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { errorResponse, successResponse, HTTP_STATUS } from '@handy-go/shared';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Local-disk storage for local dev — served back statically at /uploads
// by the gateway (see index.ts). Swap for cloud storage (S3, etc.) if
// this ever needs to run across multiple gateway instances.
const uploadsDir = path.resolve(__dirname, '../../uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    cb(null, `${randomUUID()}${path.extname(file.originalname)}`);
  },
});

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only image uploads (jpeg, png, webp, heic) are allowed'));
    }
  },
});

const router: Router = Router();

router.post('/', (req: Request, res: Response) => {
  upload.single('image')(req, res, (err: unknown) => {
    if (err) {
      const message = err instanceof Error ? err.message : 'Upload failed';
      return errorResponse(res, message, HTTP_STATUS.BAD_REQUEST);
    }
    if (!req.file) {
      return errorResponse(res, 'No image file provided', HTTP_STATUS.BAD_REQUEST);
    }

    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const url = `${protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    return successResponse(res, { url }, 'Image uploaded successfully', HTTP_STATUS.CREATED);
  });
});

export default router;
