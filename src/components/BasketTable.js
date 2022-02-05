import * as React from "react";
import { DataGrid } from "@mui/x-data-grid";
import { randomInt, randomUserName } from "@mui/x-data-grid-generator";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Button from "@mui/material/Button";

const columns = [
  { field: "id" },
  { field: "token", width: 150, editable: true },
  { field: "weight", width: 80, type: "number", editable: true },
];

export default function UpdateRowsProp(props) {
  const handleCommit = (e) => {
    const array = props.props.rows.map((r) => {
      if (r.id === e.id) {
        return { ...r, [e.field]: e.value };
      } else {
        return { ...r };
      }
    });
    props.props.setRows(array);
  };
  const handleDeleteRow = () => {
    props.props.setRows((prevRows) => {
      const rowToDeleteIndex = randomInt(0, prevRows.length - 1);
      return [
        ...props.props.rows.slice(0, rowToDeleteIndex),
        ...props.props.rows.slice(rowToDeleteIndex + 1),
      ];
    });
    props.props.setIdCounter(Math.max(props.props.idCounter - 1, 1));
  };

  const handleAddRow = () => {
    props.props.setRows((prevRows) => [
      ...prevRows,
      props.props.createBlankRow(),
    ]);
  };

  return (
    <div style={{ width: "100%" }}>
      <Stack
        sx={{ width: "100%", mb: 1 }}
        direction="row"
        alignItems="flex-start"
        columnGap={1}
      >
        <Button size="small" onClick={handleDeleteRow}>
          Delete a row
        </Button>
        <Button size="small" onClick={handleAddRow}>
          Add a row
        </Button>
      </Stack>
      <Box sx={{ height: 400, bgcolor: "background.paper" }}>
        <DataGrid
          hideFooter
          rows={props.props.rows}
          columns={columns}
          onCellEditCommit={handleCommit}
        />
      </Box>
    </div>
  );
}
