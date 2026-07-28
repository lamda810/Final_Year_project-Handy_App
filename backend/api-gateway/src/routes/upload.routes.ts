import { Router, Request, Response } from 'express';
import multer from 'multer';
import { errorResponse, successResponse, HTTP_STATUS, logger } from '@handy-go/shared';
import { uploadImage } from '@handy-go/user-service/dist/services/upload.service.js';

// Buffered in memory and streamed straight to Cloudinary — no local disk
// write. Local disk doesn't survive across Render free-tier restarts/
// redeploys (ephemeral filesystem), which made previously-uploaded images
// disappear; Cloudinary gives us durable, CDN-backed storage instead.
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];

const upload = multer({
  storage: multer.memoryStorage(),
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
  upload.single('image')(req, res, async (err: unknown) => {
    if (err) {
      const message = err instanceof Error ? err.message : 'Upload failed';
      return errorResponse(res, message, HTTP_STATUS.BAD_REQUEST);
    }
    if (!req.file) {
      return errorResponse(res, 'No image file provided', HTTP_STATUS.BAD_REQUEST);
    }

    try {
      const result = await uploadImage(req.file.buffer, 'handy-go/documents');
      return successResponse(res, { url: result.url }, 'Image uploaded successfully', HTTP_STATUS.CREATED);
    } catch (error) {
      logger.error('Image upload failed:', error);
      return errorResponse(res, 'Failed to upload image. Please try again.', HTTP_STATUS.INTERNAL_SERVER_ERROR);
    }
  });
});

export default router;
