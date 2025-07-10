const { execSync } = require("child_process");
const fs = require("fs");

// Function to get current timestamp in ISO format
function getCurrentTimestamp() {
  return new Date().toISOString();
}

// Function to get current date and time in readable format (e.g., Jul 10, 2025, 14:35)
function getCurrentDateTimeString() {
  const now = new Date();
  return now.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}

// Function to create a simple JSON file with deployment info
function createDeployInfo() {
  const now = new Date();
  const deployInfo = {
    last_deploy_date: getCurrentTimestamp(),
    deploy_timestamp: now.getTime(),
    last_deploy_local: getCurrentDateTimeString(),
  };

  // Write to a local file that can be uploaded to Firebase Storage or Firestore
  fs.writeFileSync("deploy_info.json", JSON.stringify(deployInfo, null, 2));

  console.log("✅ Deployment info created!");
  console.log(`📅 Date: ${deployInfo.last_deploy_local}`);
  console.log("📁 File: deploy_info.json");
  console.log("");
  console.log("Next steps:");
  console.log("1. Upload deploy_info.json to Firebase Storage");
  console.log("2. Or manually add the timestamp to Firestore");
  console.log("3. Or use this timestamp in your app");
}

createDeployInfo();
