import { Icon } from "@iconify/react";
import pieChart2Fill from "@iconify/icons-eva/pie-chart-2-fill";
import shoppingBagFill from "@iconify/icons-eva/shopping-bag-fill";
import lockFill from "@iconify/icons-eva/lock-fill";
import create from "@iconify/icons-eva/file-add-fill";

// ----------------------------------------------------------------------

const getIcon = (name) => <Icon icon={name} width={22} height={22} />;

const sidebarConfig = [
  {
    title: "dashboard",
    path: "/dashboard/app",
    icon: getIcon(pieChart2Fill),
  },
  {
    title: "Create a Basket",
    path: "/dashboard/create-basket",
    icon: getIcon(create),
  },
  {
    title: "View Baskets",
    path: "/dashboard/view-baskets",
    icon: getIcon(shoppingBagFill),
  },
  {
    title: "login",
    path: "/login",
    icon: getIcon(lockFill),
  },
];

export default sidebarConfig;
