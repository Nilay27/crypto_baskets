import * as React from "react";
import axios from "axios";

// material
import { Box, Grid, Container, Typography, Button, Stack } from "@mui/material";
import { Link as RouterLink, useNavigate } from "react-router-dom";
// components
import Page from "../components/Page";
import BasketCard from "../components/_dashboard/app/BasketCard";

// ----------------------------------------------------------------------

export default function DashboardApp(props) {
  let navigate = useNavigate();
  const client = axios.create({
    baseURL: "http://127.0.0.1:8000",
  });
  const [subscriptions, setSubscriptions] = React.useState(null);
  const [relevantBaskets, setRelevantBaskets] = React.useState([]);

  React.useEffect(() => {
    client
      .get("/subscriptions/get-subscriptions", {
        params: {
          user_id: props.defaultAccount,
        },
      })
      .then((response) => {
        if (response.data["HTTPStatusCode"] === 200) {
          setSubscriptions(response.data["subscriptions"].subscriptions);
        } else {
          console.log(response.data["message"]);
        }
      })
      .catch((error) => {
        console.log("Error occurred: ", error);
      });
  }, [props.defaultAccount, props.basketSubscribed]);

  React.useEffect(() => {
    let baskets = [];
    if (subscriptions != null) {
      for (const basketId in subscriptions) {
        for (const basket of props.basketsData) {
          if (basket._id === basketId) {
            baskets.push(basket);
          }
        }
      }
      setRelevantBaskets(baskets);
    }
  }, [subscriptions]);

  return (
    <Page title="Dashboard | Minimal-UI">
      <Container maxWidth="xl">
        <Box sx={{ pb: 5 }}>
          <Typography variant="h4">Hi, Welcome back</Typography>
        </Box>
        <Grid container spacing={3}>
          {relevantBaskets.map((basket, idx) => (
            <Grid
              item
              xs={12}
              sm={6}
              md={3}
              key={idx}
              sx={{
                cursor: "pointer",
              }}
              onClick={() => {
                props.setSubscribedBasket(basket);
                navigate("../subscription");
              }}
            >
              <BasketCard basketName={basket.name} value={""} />
            </Grid>
          ))}

          <Grid item xs={12}>
            <Stack direction="row" spacing={2} sx={{ mt: 3 }}>
              <RouterLink
                to="/dashboard/view-baskets"
                style={{ textDecoration: "none", color: "inherit" }}
              >
                <Button
                  fullWidth
                  size="large"
                  color="inherit"
                  variant="outlined"
                >
                  Subscribe to a Basket
                </Button>
              </RouterLink>
              <RouterLink
                to="/dashboard/create-basket"
                style={{ textDecoration: "none", color: "inherit" }}
              >
                <Button
                  fullWidth
                  size="large"
                  color="inherit"
                  variant="outlined"
                >
                  Create a Basket
                </Button>
              </RouterLink>
            </Stack>
          </Grid>
        </Grid>
      </Container>
    </Page>
  );
}
