"use client";

import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { PixelManekinekoLoader } from "@/components/ui/PixelManekinekoLoader";

const MIN_VISIBLE_MS = 420;
const MAX_VISIBLE_MS = 2800;

export function RouteTransitionLoader() {
  const pathname = usePathname();
  const [visible, setVisible] = useState(false);
  const shownAt = useRef(0);
  const pendingPath = useRef<string | null>(null);
  const fallbackTimeout = useRef<number | null>(null);

  useEffect(() => {
    function show(nextPath: string) {
      pendingPath.current = nextPath;
      shownAt.current = Date.now();
      setVisible(true);

      if (fallbackTimeout.current) {
        window.clearTimeout(fallbackTimeout.current);
      }
      fallbackTimeout.current = window.setTimeout(() => {
        pendingPath.current = null;
        setVisible(false);
      }, MAX_VISIBLE_MS);
    }

    function showForInternalLink(event: MouseEvent) {
      const target = event.target as Element | null;
      const link = target?.closest("a[href]") as HTMLAnchorElement | null;
      if (!link || link.target || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

      const nextUrl = new URL(link.href, window.location.href);
      if (nextUrl.origin !== window.location.origin || nextUrl.pathname === window.location.pathname) return;

      show(nextUrl.pathname);
    }

    document.addEventListener("click", showForInternalLink, true);
    return () => {
      document.removeEventListener("click", showForInternalLink, true);
      if (fallbackTimeout.current) {
        window.clearTimeout(fallbackTimeout.current);
      }
    };
  }, []);

  useEffect(() => {
    if (!pendingPath.current) return;

    const elapsed = Date.now() - shownAt.current;
    const delay = Math.max(0, MIN_VISIBLE_MS - elapsed);
    const timeout = window.setTimeout(() => {
      pendingPath.current = null;
      setVisible(false);
      if (fallbackTimeout.current) {
        window.clearTimeout(fallbackTimeout.current);
        fallbackTimeout.current = null;
      }
    }, delay);

    return () => window.clearTimeout(timeout);
  }, [pathname]);

  return (
    <div
      aria-hidden={!visible}
      className={`route-transition-loader ${visible ? "route-transition-loader-visible" : "route-transition-loader-hidden"}`}
    >
      <PixelManekinekoLoader />
    </div>
  );
}
