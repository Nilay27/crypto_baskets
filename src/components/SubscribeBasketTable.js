import * as React from "react";
import { DataGrid } from "@mui/x-data-grid";
import Box from "@mui/material/Box";

const columns = [
  { field: "id" },
  { field: "token", width: 150 },
  { field: "weight", width: 80, type: "number" },
];

export default function UpdateRowsProp(props) {
  return (
    <div style={{ width: "100%" }}>
      <Box sx={{ height: 400, bgcolor: "background.paper" }}>
        <DataGrid hideFooter rows={props.rows} columns={columns} />
      </Box>
    </div>
  );
}
