import * as React from "react";
import { useNavigate } from "react-router-dom";
// material
import { Container, Stack, Typography, Grid } from "@mui/material";
// components
import Page from "../components/Page";
import BasketCard from "../components/_dashboard/app/BasketCard";

// ----------------------------------------------------------------------

export default function EcommerceShop(props) {
  let navigate = useNavigate();

  return (
    <Page title="Dashboard: Baskets | Minimal-UI">
      <Container>
        <Typography variant="h4" sx={{ mb: 5 }}>
          Baskets
        </Typography>

        <Grid container spacing={3}>
          {/* {console.log(props.basketsData)} */}
          {props.basketsData.map((basket, idx) => (
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
                props.setBasketToSubscribe(basket);
                navigate("../subscribe", { replace: true });
              }}
            >
              <BasketCard basketName={basket.name} value={""} />
              {/* {Object.keys(basket.weights).map((token, idx2) => (
                  <Typography key={`${idx}-${idx2}`} textAlign="center">
                    {`${token}: ${basket.weights[token]}`}
                  </Typography>
                ))} */}
            </Grid>
          ))}
        </Grid>
      </Container>
    </Page>
  );
}
