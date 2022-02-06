import * as React from "react";
import { useNavigate } from "react-router-dom";
// material
import { Card, Stack, Button, Container, Typography } from "@mui/material";
// components
import Page from "../components/Page";
import SubscribeBasketTable from "../components/SubscribeBasketTable";
//
import {
  getContractAddress,
  subscribeToBasket,
  addFunds,
  partialExit,
} from "../utils/getContractAddress";

// ----------------------------------------------------------------------

// ----------------------------------------------------------------------

export default function User(props) {
  let navigate = useNavigate();
  const [rows, setRows] = React.useState([]);
  const [amount, setAmount] = React.useState(0);
  const [frequency, setFrequency] = React.useState(0);

  React.useEffect(() => {
    if (props.basketToSubscribe != null) {
      let idx = 1;
      let rowsToBeSet = [];
      for (const token in props.basketToSubscribe.weights) {
        rowsToBeSet.push({
          id: idx,
          token: token,
          weight: props.basketToSubscribe.weights[token],
        });
        idx += 1;
      }
      setRows(rowsToBeSet);
    }
  }, [props]);
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
            {`Change Composition of ${
              props.basketToSubscribe == null
                ? "a Basket"
                : props.basketToSubscribe.name
            }`}
          </Typography>
        </Stack>
        <Stack direction="row" alignItems="center" mb={5}>
          <Typography>Amount (ETH): </Typography>
          <input
            required
            style={{
              boxSizing: "border-box",
              padding: "0.25rem 0.25rem",
              marginLeft: "1rem",
              marginRight: "2rem",
              fontSize: "0.875rem",
              lineHeight: "1rem",
            }}
            value={amount}
            onInput={(e) => {
              setAmount(e.target.value);
            }}
          ></input>
          {/* </Stack>
        <Stack direction="row" alignItems="center" mb={5}> */}
        </Stack>

        <Card>
          <SubscribeBasketTable rows={rows} />
        </Card>
        <Button
          disabled={
            props.defaultAccount != null &&
            amount > 0 &&
            props.basketToSubscribe != null
              ? false
              : true
          }
          onClick={async () => {
            const returnedAddress = await getContractAddress(
              "ETH",
              props.provider
            );
            await subscribeToBasket(
                props.provider,
                props.basketToSubscribe._id,
                returnedAddress,
                amount,
                Object.keys(props.basketToSubscribe.weights),
                props.defaultAccount,
                frequency,
                navigate,
                props.setBasketSubscribed
              );
              console.log("Funds Added");
          }}
        >
          Invest More
        </Button>

        <Button
          disabled={
            props.defaultAccount != null &&
            amount > 0 &&
            props.basketToSubscribe != null
              ? false
              : true
          }
          onClick={async () => {
            const desiredToken = await getContractAddress(
              "WETH",
              props.provider
            );
            await partialExit(
              props.provider,
              props.basketToSubscribe._id,
              desiredToken,
              amount,
            );
            console.log("Partial Exit");
          }}
        >
          Partial Exit
        </Button>

      </Container>
    </Page>
  );
}
