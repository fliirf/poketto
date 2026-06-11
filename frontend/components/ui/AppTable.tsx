export function AppTable({
  headers,
  children,
  columnClasses = [],
  headerClasses = []
}: {
  headers: string[];
  children: React.ReactNode;
  columnClasses?: string[];
  headerClasses?: string[];
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] table-fixed border-separate border-spacing-y-2 text-left">
        {columnClasses.length ? (
          <colgroup>
            {headers.map((header, index) => (
              <col key={header} className={columnClasses[index] ?? ""} />
            ))}
          </colgroup>
        ) : null}
        <thead>
          <tr>
            {headers.map((header, index) => (
              <th
                key={header}
                className={`px-3 py-2 text-xs font-bold uppercase tracking-normal text-slate-400 ${headerClasses[index] ?? ""}`}
              >
                {header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}
