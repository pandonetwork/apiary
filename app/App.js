import React from 'react'
import {
  AragonApp,
  AppView,
  AppBar,
  Button,
  SidePanel,
  PublicUrl,
  BaseStyles,
  EmptyStateCard,
  Text,
  Badge,
  Info,
  TabBar,
  IconHome,
  Table, TableHeader, TableRow, TableCell,
  observe,
  theme
} from '@aragon/ui'
import PropTypes from 'prop-types'
import Aragon, { providers } from '@aragon/client'
import styled from 'styled-components'
import web3Utils from 'web3-utils'
import TransferPanel from './components/Transfer/TransferPanel'

import WithdrawPanel from './components/Withdraw/WithdrawPanel'

import UpdateTapPanel from './components/UpdateTap/UpdateTapPanel'

function WithdrawalsTable(props) {
  const withdrawals = props.withdrawals

  if(withdrawals.length === 0) { return('') }

  const items = withdrawals.map((withdrawal) => {
    return(
      <TableRow>
        <TableCell><Text color={theme.negative}>- {web3Utils.fromWei(withdrawal.value.toString(), 'ether')} ETH</Text></TableCell>
      </TableRow>
    )
  })

  return (
    <Table header={<TableRow><TableHeader title="Withdrawals" /></TableRow>}>{items}</Table>
  )
}

function TransactionsTable(props) {
  const transactions = props.transactions

  if(transactions.length === 0) {
    return(
      <EmptyStateCard
        text="No transactions yet"
        icon={<IconHome color="blue" />}
      />
    )
  }

  const items = transactions.map((transaction) => {
      if (transaction.type === 'buy') {
        return(
          <TableRow>
            <TableCell><Badge.Identity>{transaction.to}</Badge.Identity></TableCell>
            <TableCell><Text color={theme.positive}>+ {web3Utils.fromWei(transaction.eth.toString(), 'ether')} ETH</Text></TableCell>
            <TableCell><Text>+ {web3Utils.fromWei(transaction.tokens.toString(), 'ether')} ABT</Text></TableCell>
          </TableRow>
        )
      } else if (transaction.type === 'sell') {
        return(
          <TableRow>
            <TableCell><Badge.Identity>{transaction.from}</Badge.Identity></TableCell>
            <TableCell><Text color={theme.negative}>- {web3Utils.fromWei(transaction.eth.toString(), 'ether')} ETH</Text></TableCell>
            <TableCell><Text>- {web3Utils.fromWei(transaction.tokens.toString(), 'ether')} ABT</Text></TableCell>
          </TableRow>
        )
      }
  })

  return (
    <Table header={<TableRow><TableHeader title="Buys / sells" /></TableRow>}>{items}</Table>
  )
}

export default class App extends React.Component {
  static propTypes = {
    app: PropTypes.object.isRequired
  }

  static defaultProps = {
    transactions: [],
    withdrawals: [],
    account: '',
    token: '',
    supply: '',
    pool: '',
    tap: '',
  }

  state = {
    transferPanelOpened: false,
    withdrawPanelOpened: false,
    updateTapPanelOpened: false,
  }

  openTransferPanel = () => {
    this.setState({ transferPanelOpened: true, withdrawPanelOpened: false, updateTapPanelOpened: false })
  }

  closeTransferPanel = () => {
    this.setState({ transferPanelOpened: false })
  }

  openWithdrawPanel = () => {
    this.setState({ withdrawPanelOpened: true, transferPanelOpened: false, updateTapPanelOpened: false })
  }

  closeWithdrawPanel = () => {
    this.setState({ withdrawPanelOpened: false })
  }

  openUpdateTapPanel = () => {
    this.setState({ updateTapPanelOpened: true, withdrawPanelOpened: false, transferPanelOpened: false })
  }

  closeUpdateTapPanel = () => {
    this.setState({ updateTapPanelOpened: false })
  }

  render () {
    console.log(this.state)
    console.log(this.props)

    return (
      <PublicUrl.Provider url="./aragon-ui/">
        <BaseStyles />
        <Main>
          <AppView
            appBar={<AppBar
              title="Apiary"
              endContent={
                <ButtonsWrapper>
                  <Button mode="strong" onClick={this.openTransferPanel}>Buy / sell</Button>
                  <Button mode="strong" onClick={this.openWithdrawPanel}>Withdraw</Button>
                  <Button mode="strong" onClick={this.openUpdateTapPanel}>Update tap</Button>

                </ButtonsWrapper>
              }/>
            }>

            <Table header={<TableRow><TableHeader title="Informations" /></TableRow>}>
              <TableRow>
                <TableCell>ERC20: {this.props.token}</TableCell>
                <TableCell>Pool: {web3Utils.fromWei(this.props.pool.toString(), 'ether')} ETH</TableCell>
                <TableCell>Supply: {web3Utils.fromWei(this.props.supply.toString(), 'ether')} ABT</TableCell>
                <TableCell>Tap: {Math.round(web3Utils.fromWei(this.props.tap.toString(), 'ether') * 24 * 3600)} ETH / day</TableCell>

              </TableRow>
            </Table>

            <TableWrapper>
              <TransactionsTable transactions={this.props.transactions} />
            </TableWrapper>

            <TableWrapper>
              <WithdrawalsTable withdrawals={this.props.withdrawals} />
            </TableWrapper>

          </AppView>

          <SidePanel
            opened={this.state.transferPanelOpened}
            onClose={this.closeTransferPanel}
            title="Buy / sell">
            <TransferPanel />
          </SidePanel>

          <SidePanel
            opened={this.state.withdrawPanelOpened}
            onClose={this.closeWithdrawPanel}
            title="Withdraw">
            <WithdrawPanel />
          </SidePanel>

          <SidePanel
            opened={this.state.updateTapPanelOpened}
            onClose={this.closeUpdateTapPanel}
            title="Update tap">
            <UpdateTapPanel />
          </SidePanel>

        </Main>
      </PublicUrl.Provider>


    )
  }
}

const Main = styled.div`
  height: 100vh;
`

const ButtonsWrapper = styled.div`
  button {
    margin-right: 20px;
  }

  button:last-child {
    margin-right: 0;
  }
`

const TableWrapper = styled.div`
  display: flex;
  justify-content: space-evenly;
  align-items: center;
  flex-grow: 1;
`
