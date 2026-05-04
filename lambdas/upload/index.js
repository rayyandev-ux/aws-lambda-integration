const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { v4: uuidv4 } = require("uuid");
const busboy = require("busboy");

const s3 = new S3Client({});

const ALLOWED_TYPES = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
};

exports.handler = async (event) => {
  const contentType = event.headers["content-type"] || "";

  let buffer;
  let mimetype;

  if (contentType.includes("multipart/form-data")) {
    const result = await parseMultipart(event);
    buffer = result.buffer;
    mimetype = result.mimetype;
  } else {
    const body = JSON.parse(event.body);
    mimetype = body.mimetype;
    buffer = Buffer.from(body.data, "base64");
  }

  if (!ALLOWED_TYPES[mimetype]) {
    return { statusCode: 400, body: JSON.stringify({ error: "Tipo no permitido" }) };
  }

  if (buffer.byteLength > 10 * 1024 * 1024) {
    return { statusCode: 400, body: JSON.stringify({ error: "Imagen mayor a 10 MB" }) };
  }

  const key = `${process.env.UPLOAD_PREFIX}/${uuidv4()}.${ALLOWED_TYPES[mimetype]}`;

  await s3.send(new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    Body: buffer,
    ContentType: mimetype,
  }));

  return { statusCode: 200, body: JSON.stringify({ key }) };
};

const parseMultipart = (event) => {
  return new Promise((resolve, reject) => {
    const bb = busboy({ headers: event.headers });
    let buffer;
    let mimetype;

    bb.on("file", (_field, file, info) => {
      mimetype = info.mimeType;
      const chunks = [];
      file.on("data", (chunk) => chunks.push(chunk));
      file.on("end", () => { buffer = Buffer.concat(chunks); });
    });

    bb.on("finish", () => resolve({ buffer, mimetype }));
    bb.on("error", reject);

    bb.write(Buffer.from(event.body, event.isBase64Encoded ? "base64" : "utf8"));
    bb.end();
  });
};