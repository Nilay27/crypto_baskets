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
  getTokenValue,
} from "../utils/getContractAddress";

// ----------------------------------------------------------------------

// ----------------------------------------------------------------------

export default function User(props) {
  let navigate = useNavigate();
  const [rows, setRows] = React.useState([]);
  const [amounts, setAmounts] = React.useState(null);
  const [values, setValue] = React.useState(null);

  React.useEffect(() => {
    const fetchAmounts = async () => {
      let tokenAmounts = [];
      for (const token in props.subscribedBasket.weights) {
        const returnedAddress = await getContractAddress(token, props.provider);
        const tokenAmount = await getUserHoldingForBasket(
          props.defaultAccount,
          props.subscribedBasket._id,
          returnedAddress,
          props.provider
        );
        tokenAmounts.push(tokenAmount);
      }
      setAmounts(tokenAmounts);
      console.log('first tokenAmounts', tokenAmounts);
    };

    if (props.subscribedBasket != null) {
      fetchAmounts();
    }
  }, [props]);

  React.useEffect(() => {
    const fetchAmounts = async () => {
      let tokenValues = [];
      console.log(props.subscribedBasket);
      for (const token in props.subscribedBasket.weights) {
        // const returnedAddress = await getContractAddress(token, props.provider);
        const tokenAmount = await getTokenValue(
          token,
          props.provider
        );
        tokenValues.push(tokenAmount);
      }
      console.log(tokenValues);
      setValue(tokenValues);
    };

    if (props.subscribedBasket != null) {
      fetchAmounts();
    }
  }, [props]);

  React.useEffect(() => {
    if (amounts != null && values!=null) {
      let idx = 1;
      let rowsToBeSet = [];
      for (const token in props.subscribedBasket.weights) {
        rowsToBeSet.push({
          id: idx,
          token: token,
          weight: props.subscribedBasket.weights[token],
          amount: amounts[idx - 1],
          value: values[idx-1]*amounts[idx - 1],
        });
        console.log(values[idx-1])
        idx += 1; 
      }
      setRows(rowsToBeSet);
    }
  }, [amounts,values]);

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
            navigate("../invest_more", { replace: true });
          }}
        >
          Change Composition
        </Button>
        <Button
          disabled={
            props.defaultAccount != null && props.subscribedBasket != null
              ? false
              : true
          }
          onClick={async () => {
            const tokens = rows.map((row) => row.token);
            // console.log("tokens", tokens);
            for (let token of tokens) {
              token = token.toUpperCase();

              const returnedAddress = await getContractAddress(
                token,
                props.provider
              );
              // console.log("checking user approval");
              await getApproval(
                returnedAddress,
                props.provider,
                props.defaultAccount
              );
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
