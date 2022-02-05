// material
import { styled } from "@mui/material/styles";
import { Card, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import BasketImage from "../../../assets/basket.png";

// ----------------------------------------------------------------------

const RootStyle = styled(Card)(({ theme }) => ({
  boxShadow: "none",
  textAlign: "center",
  padding: theme.spacing(5, 0),
  color: theme.palette.primary.darker,
  backgroundColor: theme.palette.primary.lighter,
}));

// ----------------------------------------------------------------------

export default function BasketCard(props) {
  return (
    <RootStyle>
      <Box component="img" src={BasketImage} />
      <Typography variant="h3">{props.value}</Typography>
      <Typography variant="subtitle2" sx={{ opacity: 0.72 }}>
        {props.basketName}
      </Typography>
    </RootStyle>
  );
}
