/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone", // enables tiny multi-stage Docker image
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000",
  },
};

module.exports = nextConfig;
