import * as React from "react";
import { v4 as uuidv4 } from "uuid";
import { useNavigate } from "react-router-dom";

// material
import { Card, Stack, Button, Container, Typography } from "@mui/material";
// components
import Page from "../components/Page";
import BasketTable from "../components/BasketTable";
//
import { getContractAddress, createBasket } from "../utils/getContractAddress";

export default function User(props) {
  let navigate = useNavigate();

  const [basketName, setBasketName] = React.useState("");
  const [idCounter, setIdCounter] = React.useState(1);
  const createBlankRow = () => {
    setIdCounter(idCounter + 1);
    return { id: idCounter, token: "", weight: 0 };
  };
  const [rows, setRows] = React.useState([]);
  const tableProps = {
    idCounter: idCounter,
    setIdCounter: setIdCounter,
    rows: rows,
    setRows: setRows,
    createBlankRow: createBlankRow,
  };

  return (
    <Page title="User | Minimal-UI">
      <Container>
        <Stack
          direction="row"
          alignItems="center"
          justifyContent="space-between"
          mb={5}
        >
          <Typography variant="h4" gutterBottom>
            Create a Basket
          </Typography>
        </Stack>
        <Stack direction="row" alignItems="center" mb={5}>
          <Typography>Enter Name of the Basket: </Typography>
          <input
            required
            style={{
              boxSizing: "border-box",
              padding: "0.25rem 0.5rem",
              marginLeft: "1rem",
              fontSize: "0.875rem",
              lineHeight: "1rem",
            }}
            value={basketName}
            onInput={(e) => {
              setBasketName(e.target.value);
            }}
          ></input>
        </Stack>

        <Card>
          <BasketTable props={tableProps} />
        </Card>
        <Button
          disabled={rows.length > 0 && basketName !== "" ? false : true}
          onClick={async () => {
            const tokens = rows.map((row) => row.token.toUpperCase());
            const weights = rows.map((row) => parseInt(row.weight));
            let contractAddresses = [];
            for (let token of tokens) {
              const returnedAddress = await getContractAddress(
                token,
                props.provider
              );
              contractAddresses.push(returnedAddress);
            }
            const basketId = uuidv4();
            await createBasket(
              props.provider,
              contractAddresses,
              weights,
              basketId,
              basketName,
              navigate,
              props.defaultAccount,
              tokens,
              props.setBasketCreated
            );
          }}
        >
          Create
        </Button>
      </Container>
    </Page>
  );
}
