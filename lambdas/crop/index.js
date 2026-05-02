const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({});

const CIRCLE_MASK = Buffer.from(
  `<svg><circle cx="20" cy="20" r="20"/></svg>`
);

exports.handler = async (event) => {
  const failed = [];

  for (const record of event.Records) {
    try {
      const s3Event = JSON.parse(record.body);
      const srcKey = decodeURIComponent(s3Event.Records[0].s3.object.key);

      const outKey = srcKey
        .replace(process.env.UPLOAD_PREFIX, process.env.PROCESSED_PREFIX)
        .replace(/\.[^.]+$/, "_circular.png");

      const response = await s3.send(new GetObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: srcKey,
      }));

      const inputBuffer = Buffer.from(await response.Body.transformToByteArray());

      const outputBuffer = await sharp(inputBuffer)
        .resize(40, 40, { fit: "cover" })
        .composite([{ input: CIRCLE_MASK, blend: "dest-in" }])
        .png()
        .toBuffer();

      await s3.send(new PutObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: outKey,
        Body: outputBuffer,
        ContentType: "image/png",
      }));

    } catch (err) {
      console.error("Error procesando mensaje pipipi", record.messageId, err);
      failed.push(record.messageId);
    }
  }

  return { batchItemFailures: failed.map(id => ({ itemIdentifier: id })) };
};