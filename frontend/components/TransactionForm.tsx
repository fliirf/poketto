"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, AppTextarea, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api, type TransactionPayload } from "@/lib/api";
import { formatNumberInput, parseNumberInput, toDateInput } from "@/lib/format";
import type { Category, Transaction, TransactionType } from "@/types/poketto";

type LocationPayload = Pick<TransactionPayload, "location_lat" | "location_lng" | "location_name">;

function geolocationErrorMessage(error: unknown) {
  if (typeof GeolocationPositionError !== "undefined" && error instanceof GeolocationPositionError) {
    if (error.code === error.PERMISSION_DENIED) {
      return "Izin lokasi ditolak oleh browser atau sistem operasi.";
    }
    if (error.code === error.POSITION_UNAVAILABLE) {
      return "Posisi perangkat belum tersedia. Coba aktifkan Location Services di Windows.";
    }
    if (error.code === error.TIMEOUT) {
      return "Pengambilan lokasi terlalu lama. Coba lagi atau gunakan lokasi perkiraan.";
    }
  }

  return "Lokasi browser belum bisa dibaca.";
}

export function TransactionForm({
  categories,
  transaction
}: {
  categories: Category[];
  transaction?: Transaction;
}) {
  const router = useRouter();
  const toast = useToast();
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [locationEnabled, setLocationEnabled] = useState(false);
  const [locationStatus, setLocationStatus] = useState("");
  const [locationPayload, setLocationPayload] = useState<LocationPayload>(() => ({
    location_lat: transaction?.location_lat ?? null,
    location_lng: transaction?.location_lng ?? null,
    location_name: transaction?.location_name ?? null
  }));
  const [locating, setLocating] = useState(false);
  const [amountInput, setAmountInput] = useState(() => formatNumberInput(transaction?.amount));
  const [form, setForm] = useState<TransactionPayload>({
    type: transaction?.type ?? "expense",
    category_id: transaction?.category_id ?? null,
    amount: transaction?.amount ?? 0,
    transaction_date: toDateInput(transaction?.date ?? transaction?.transaction_date),
    description: transaction?.description ?? ""
  });
  const availableCategories = useMemo(
    () => categories.filter((category) => category.type === form.type),
    [categories, form.type]
  );

  useEffect(() => {
    api
      .userSettings()
      .then((data) => {
        const enabled = toBoolean(data.user_settings.location_enabled);
        setLocationEnabled(enabled);
        if (!enabled) {
          setLocationPayload({ location_lat: null, location_lng: null, location_name: null });
          setLocationStatus("");
        }
      })
      .catch(() => setLocationEnabled(false));
  }, []);

  async function reverseGeocode(latitude: number, longitude: number) {
    try {
      const response = await fetch(
        `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=id`
      );
      const data = await response.json();
      const parts = [
        data.locality,
        data.city && data.city !== data.locality ? data.city : null,
        data.principalSubdivision
      ].filter(Boolean);

      if (parts.length) return parts.join(", ");
    } catch {
      // Try the next public reverse-geocode source below.
    }

    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latitude}&lon=${longitude}&zoom=14&addressdetails=1&accept-language=id`
      );
      const data = await response.json();
      const address = data.address ?? {};
      const locality = address.village ?? address.suburb ?? address.town ?? address.city_district ?? address.city;
      const region = address.county ?? address.city ?? address.state;
      const parts = [locality, region && region !== locality ? region : null].filter(Boolean);

      if (parts.length) return parts.join(", ");
    }
    catch {
      return null;
    }

    return null;
  }

  async function resolveApproximateLocation(): Promise<LocationPayload> {
    try {
      const response = await fetch("https://ipwho.is/");
      const data = await response.json();

      if (!data.success || typeof data.latitude !== "number" || typeof data.longitude !== "number") {
        return {};
      }

      const latitude = Number(data.latitude.toFixed(7));
      const longitude = Number(data.longitude.toFixed(7));
      const parts = [data.city, data.region].filter(Boolean);
      const nextLocation = {
        location_lat: latitude,
        location_lng: longitude,
        location_name: parts.length ? `${parts.join(", ")} (perkiraan)` : "Lokasi perkiraan"
      };

      setLocationPayload(nextLocation);
      setLocationStatus(`Lokasi perkiraan: ${nextLocation.location_name}`);

      return nextLocation;
    } catch {
      return {};
    }
  }

  async function resolveBrowserLocation({ silent = false }: { silent?: boolean } = {}): Promise<LocationPayload> {
    if (form.type !== "expense" || !locationEnabled || typeof navigator === "undefined" || !navigator.geolocation) {
      return {};
    }

    setLocating(true);
    setLocationStatus("Mengambil lokasi...");

    try {
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: false,
          timeout: 20_000,
          maximumAge: 300_000
        });
      });

      const latitude = Number(position.coords.latitude.toFixed(7));
      const longitude = Number(position.coords.longitude.toFixed(7));
      const locationName = await reverseGeocode(latitude, longitude);
      const nextLocation = {
        location_lat: latitude,
        location_lng: longitude,
        location_name: locationName ?? "Lokasi transaksi"
      };

      setLocationPayload(nextLocation);
      setLocationStatus(locationName ? `Lokasi berhasil: ${locationName}` : "Lokasi berhasil ditambahkan.");

      return nextLocation;
    } catch (error) {
      const reason = geolocationErrorMessage(error);
      const approximateLocation = await resolveApproximateLocation();
      if (approximateLocation.location_lat) {
        if (!silent) {
          toast.success("Lokasi presisi belum tersedia, memakai lokasi perkiraan.");
        }
        return approximateLocation;
      }

      setLocationStatus(`${reason} Transaksi tetap bisa disimpan tanpa lokasi.`);
      if (!silent) {
        toast.error(reason);
      }
      return {};
    } finally {
      setLocating(false);
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (saving) return;
    setError("");
    if (!form.category_id) {
      const message = "Kategori wajib dipilih.";
      setError(message);
      toast.error(message);
      return;
    }
    if (!form.amount || Number(form.amount) <= 0) {
      const message = "Nominal wajib diisi.";
      setError(message);
      toast.error(message);
      return;
    }
    if (!form.transaction_date) {
      const message = "Tanggal transaksi wajib diisi.";
      setError(message);
      toast.error(message);
      return;
    }

    setSaving(true);
    try {
      const latestLocation = form.type !== "expense" || !locationEnabled
        ? { location_lat: null, location_lng: null, location_name: null }
        : locationPayload.location_lat
          ? locationPayload
          : await resolveBrowserLocation({ silent: true });
      const payload = { ...form, ...latestLocation };

      if (transaction) {
        await api.updateTransaction(transaction.id, payload);
        toast.success("Transaksi berhasil diperbarui.");
      } else {
        await api.createTransaction(payload);
        toast.success(form.type === "income" ? "Berhasil tambah pemasukan." : "Berhasil tambah pengeluaran.");
      }
      router.push("/dashboard");
      router.refresh();
    } catch (err) {
      const message = err instanceof Error ? err.message : "Gagal menyimpan transaksi. Periksa kembali data yang diisi.";
      setError(message);
      toast.error(message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <AppCard className="mx-auto max-w-2xl">
      <form onSubmit={submit} className="grid gap-4">
        {error ? <ErrorState message={error} /> : null}
        <Field label="Tipe">
          <AppSelect
            value={form.type}
            onChange={(event) => {
              const nextType = event.target.value as TransactionType;
              const currentCategory = categories.find((category) => category.id === form.category_id);
              if (nextType === "income") {
                setLocationPayload({ location_lat: null, location_lng: null, location_name: null });
                setLocationStatus("");
              }
              setForm({
                ...form,
                type: nextType,
                category_id: currentCategory?.type === nextType ? form.category_id : null
              });
            }}
          >
            <option value="expense">Pengeluaran</option>
            <option value="income">Pemasukan</option>
          </AppSelect>
        </Field>
        <Field label="Nominal">
          <AppInput
            type="text"
            inputMode="numeric"
            value={amountInput}
            placeholder="Contoh: 10.000"
            onChange={(event) => {
              const formatted = formatNumberInput(event.target.value);
              setAmountInput(formatted);
              setForm({ ...form, amount: parseNumberInput(formatted) });
            }}
            required
          />
        </Field>
        <Field label="Kategori">
          <AppSelect
            value={form.category_id ?? ""}
            onChange={(event) => setForm({ ...form, category_id: event.target.value ? Number(event.target.value) : null })}
            required
          >
            <option value="">Pilih kategori</option>
            {availableCategories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name} ({category.type === "income" ? "Pemasukan" : "Pengeluaran"})
              </option>
            ))}
          </AppSelect>
          {!availableCategories.length ? (
            <span className="text-xs font-semibold text-red-600">
              Belum ada kategori {form.type === "income" ? "pemasukan" : "pengeluaran"}. Tambahkan kategori dulu.
            </span>
          ) : null}
        </Field>
        <Field label="Tanggal">
          <AppInput
            type="date"
            value={form.transaction_date}
            onChange={(event) => setForm({ ...form, transaction_date: event.target.value })}
            required
          />
        </Field>
        <Field label="Catatan">
          <AppTextarea
            rows={4}
            value={form.description ?? ""}
            placeholder="Contoh: makan siang, gaji, transportasi"
            onChange={(event) => setForm({ ...form, description: event.target.value })}
          />
        </Field>
        {form.type === "expense" && locationEnabled ? (
          <div className="rounded-2xl bg-slate-50 px-4 py-3">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div className="text-xs font-semibold text-slate-500">
                <p>Lokasi aktif untuk pengeluaran.</p>
                <p className="text-poketto-700">
                  {locationStatus || locationPayload.location_name || "Ambil lokasi sebelum menyimpan. Jika lokasi presisi gagal, Poketto akan coba lokasi perkiraan."}
                </p>
              </div>
              <AppButton
                type="button"
                variant="secondary"
                className="min-h-10 shrink-0 rounded-xl text-xs"
                disabled={locating || saving}
                onClick={() => resolveBrowserLocation()}
              >
                {locating ? "Mengambil..." : locationPayload.location_lat ? "Ambil ulang" : "Ambil lokasi"}
              </AppButton>
            </div>
          </div>
        ) : null}
        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <AppButton type="button" variant="secondary" onClick={() => router.back()}>
            Batal
          </AppButton>
          <AppButton type="submit" disabled={saving}>
            {saving ? "Menyimpan..." : transaction ? "Simpan perubahan" : "Simpan transaksi"}
          </AppButton>
        </div>
      </form>
    </AppCard>
  );
}

function toBoolean(value: unknown) {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value === 1;
  if (typeof value === "string") return ["1", "true", "on", "yes"].includes(value.toLowerCase());

  return false;
}
