import * as React from "react";
import { useNavigate } from "react-router-dom";
// material
import { Card, Stack, Button, Container, Typography } from "@mui/material";
// components
import Page from "../components/Page";
import SubscriptionBasketTable from "../components/SubscriptionBasketTable";
//
import {
  getUserHoldingForBasket,
  getContractAddress,
  exitBasket,
  getApproval,
} from "../utils/getContractAddress";

// ----------------------------------------------------------------------

// ----------------------------------------------------------------------

export default function User(props) {
  let navigate = useNavigate();
  const [rows, setRows] = React.useState([]);

  React.useEffect(() => {
    if (props.subscribedBasket != null) {
      let idx = 1;
      let rowsToBeSet = [];
      for (const token in props.subscribedBasket.weights) {
        rowsToBeSet.push({
          id: idx,
          token: token,
          weight: props.subscribedBasket.weights[token],
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
            {`${
              props.subscribedBasket == null
                ? "Subscribe to a Basket"
                : props.subscribedBasket.name
            }`}
          </Typography>
        </Stack>

        <Card>
          <SubscriptionBasketTable rows={rows} />
        </Card>
        <Button
          disabled={
            props.defaultAccount != null && props.subscribedBasket != null
              ? false
              : true
          }
          onClick={() => {
            
            props.setBasketToSubscribe(props.subscribedBasket);
            navigate("../subscribe", { replace: true });
          }}
        >
          Invest More
        </Button>
        <Button
          disabled={
            props.defaultAccount != null && props.subscribedBasket != null
              ? false
              : true
          }
          onClick={async () => {
            const tokens = rows.map((row) => row.token);
            console.log("tokens",tokens);
            for (let token of tokens) {
              token = token.toUpperCase();
              
              const returnedAddress = await getContractAddress(
                token,
                props.provider
              );
              console.log("trying new function");
              await getUserHoldingForBasket(props.defaultAccount,props.subscribedBasket._id,returnedAddress, props.provider);
              console.log("checking user approval");
              await getApproval(returnedAddress, props.provider, props.defaultAccount);
            }
            const desiredToken = await getContractAddress(
              "WETH",
              props.provider
            );
            await exitBasket(
              props.provider,
              props.subscribedBasket._id,
              desiredToken,
              props.defaultAccount,
              navigate
            );
            console.log("Basket Exited.");
            
          }}
        >
          Exit Basket
        </Button>
      </Container>
    </Page>
  );
}
