This is the **AgriCare website** (landing page + Super Admin panel) built with **Next.js**.

## Getting Started

### Run locally

Copy environment template:

- Create `website/.env.local` (copy from `website/.env.local.example`)
- Set `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and `AUTH_SECRET`

Then run:

```bash
npm run dev -- --port 3005
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open `http://localhost:3005` in your browser.

### Admin panel

- **Landing page**: `/`
- **Admin panel**: `/admin` (redirects to `/admin/login` if not authenticated)

Admin features implemented (FR22–FR26):

- **FR22**: Profile view/update + secure logout
- **FR23**: Sellers list + create/edit/disable/delete
- **FR24**: News/announcements create/edit/remove
- **FR25**: Approve/reject marketplace listings
- **FR26**: Monitor chats, remove messages, block/unblock users

Data is stored in simple JSON files under `website/data/` for now (easy to swap to your real backend later).

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
