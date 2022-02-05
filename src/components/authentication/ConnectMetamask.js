import * as React from "react";
import { ethers } from "ethers";
import { Box } from "@mui/material";
import Metamask from "../../assets/MetaMask.png";

export default function WalletCard(props) {
  const connectWalletHandler = () => {
    if (window.ethereum && props.props.defaultAccount == null) {
      // set ethers provider
      props.props.setProvider(
        new ethers.providers.Web3Provider(window.ethereum)
      );

      // connect to metamask
      window.ethereum
        .request({ method: "eth_requestAccounts" })
        .then((result) => {
          props.props.setConnButtonText("Wallet Connected");
          props.props.setDefaultAccount(result[0]);
        })
        .catch((error) => {
          props.props.setErrorMessage(error.message);
        });
    } else if (!window.ethereum) {
      console.log("Need to install MetaMask");
      props.props.setErrorMessage(
        "Please install MetaMask browser extension to interact"
      );
    }
  };

  React.useEffect(() => {
    if (props.props.defaultAccount) {
      props.props.provider
        .getBalance(props.props.defaultAccount)
        .then((balanceResult) => {
          props.props.setUserBalance(ethers.utils.formatEther(balanceResult));
        });
    }
  }, [props.props.defaultAccount, props.props.provider]);

  return (
    <div className="walletCard">
      <h4> Connection to MetaMask using ethers.js </h4>
      <Box
        sx={{
          cursor: "pointer",
          border: "1px solid black",
          borderRadius: "2.5rem",
          width: "33%",
        }}
        onClick={connectWalletHandler}
        component="img"
        src={Metamask}
      ></Box>
      <div className="accountDisplay">
        <h3>Address: {props.props.defaultAccount}</h3>
      </div>
      <div className="balanceDisplay">
        <h3>Balance: {props.props.userBalance}</h3>
      </div>
      {props.props.errorMessage}
    </div>
  );
}
