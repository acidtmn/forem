import { h, createContext } from 'preact';
import { useReducer } from "preact/hooks";

const store = createContext({});
const { Provider } = store;

/**
 * Provides state management for the Connect feature of Forem.
 *
 * @param {object} props
 * @param {JSX.Element} props.children Child React elements
 * @param {object} props.initialState The initial value to store as state
 * @param {Function} props.reducer Given the current state and an action, returns the new state
 */

const ConnectStateProvider = ({ children, initialState, reducer }) => {
  const [state, dispatch] = useReducer(reducer, initialState);
  // const state = initialState;
  // console.log(state, 'IamState');
  return <Provider value={{ state, dispatch }}>{children}</Provider>;
};
export { store, ConnectStateProvider };
