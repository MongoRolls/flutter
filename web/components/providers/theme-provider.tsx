"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return (
    <NextThemesProvider
      attribute="class"
      defaultTheme="light"
      enableSystem={false}
      disableTransitionOnChange={false}
      enableColorScheme
      storageKey="kelem-theme"
      value={{ light: "light", dark: "dark" }}
      {...props}
    >
      {children}
    </NextThemesProvider>
  );
}
