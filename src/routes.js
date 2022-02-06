import * as React from "react";
import { Navigate, useRoutes } from "react-router-dom";
import axios from "axios";
// layouts
import DashboardLayout from "./layouts/dashboard";
import LogoOnlyLayout from "./layouts/LogoOnlyLayout";
//
import Login from "./pages/Login";
import DashboardApp from "./pages/DashboardApp";
import Products from "./pages/Products";
import NotFound from "./pages/Page404";
import CreateBasket from "./pages/CreateBasket";
import Subscribe from "./pages/Subscribe";
import SubscribedBasket from "./pages/SubscribedBasket";
import InvestMore from "./pages/InvestMore"

// ----------------------------------------------------------------------
// import SubscribeBasket from "./abis/Subscribe.json";

export default function Router() {
  const [errorMessage, setErrorMessage] = React.useState(null);
  const [defaultAccount, setDefaultAccount] = React.useState(null);
  const [userBalance, setUserBalance] = React.useState(null);
  const [connButtonText, setConnButtonText] = React.useState("Connect Wallet");
  const [provider, setProvider] = React.useState(null);
  const [basketToSubscribe, setBasketToSubscribe] = React.useState(null);
  const [subscribedBasket, setSubscribedBasket] = React.useState(null);
  const [basketsData, setBasketsData] = React.useState([]);
  const [basketCreated, setBasketCreated] = React.useState(true);
  const [basketSubscribed, setBasketSubscribed] = React.useState(true);
  const client = axios.create({
    baseURL: "http://127.0.0.1:8000",
  });

  React.useEffect(() => {
    if (basketCreated) {
      client
        .get("/baskets/get-all-baskets")
        .then((response) => {
          if (response.data["HTTPStatusCode"] === 200) {
            setBasketsData(response.data["baskets"]);
          } else {
            console.log(response.data["message"]);
          }
        })
        .catch((error) => {
          console.log("Error occurred: ", error);
        });
      setBasketCreated(false);
    }
  }, [basketCreated]);

  const props = {
    errorMessage: errorMessage,
    setErrorMessage: setErrorMessage,
    defaultAccount: defaultAccount,
    setDefaultAccount: setDefaultAccount,
    userBalance: userBalance,
    setUserBalance: setUserBalance,
    connButtonText: connButtonText,
    setConnButtonText: setConnButtonText,
    provider: provider,
    setProvider: setProvider,
  };

  return useRoutes([
    {
      path: "/dashboard",
      element: <DashboardLayout />,
      children: [
        { element: <Navigate to="/dashboard/app" replace /> },
        {
          path: "app",
          element: (
            <DashboardApp
              setSubscribedBasket={setSubscribedBasket}
              defaultAccount={defaultAccount}
              basketsData={basketsData}
              basketSubscribed={basketSubscribed}
            />
          ),
        },
        {
          path: "view-baskets",
          element: (
            <Products
              setBasketToSubscribe={setBasketToSubscribe}
              basketsData={basketsData}
              setBasketsData={setBasketsData}
            />
          ),
        },
        {
          path: "create-basket",
          element: (
            <CreateBasket
              provider={provider}
              defaultAccount={defaultAccount}
              setBasketCreated={setBasketCreated}
            />
          ),
        },
        {
          path: "subscribe",
          element: (
            <Subscribe
              provider={provider}
              defaultAccount={defaultAccount}
              basketToSubscribe={basketToSubscribe}
              setBasketSubscribed={setBasketSubscribed}
            />
          ),
        },
        {
          path: "invest_more",
          element: (
            <InvestMore
              provider={provider}
              defaultAccount={defaultAccount}
              basketToSubscribe={basketToSubscribe}
              setBasketSubscribed={setBasketToSubscribe}
            />
          ),
        },
        {
          path: "subscription",
          element: (
            <SubscribedBasket
              provider={provider}
              defaultAccount={defaultAccount}
              subscribedBasket={subscribedBasket}
              setBasketToSubscribe={setBasketToSubscribe}
            />
          ),
        },
      ],
    },
    {
      path: "/",
      element: <LogoOnlyLayout />,
      children: [
        { path: "login", element: <Login props={props} /> },
        { path: "404", element: <NotFound /> },
        { path: "/", element: <Navigate to="/dashboard" /> },
        { path: "*", element: <Navigate to="/404" /> },
      ],
    },
    { path: "*", element: <Navigate to="/404" replace /> },
  ]);
}
