// jest.setup.ts: runs before every test file.
// The library's own stand-in: there is no native side in Jest to measure the safe areas.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
