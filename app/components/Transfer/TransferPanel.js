import React from 'react'
import styled from 'styled-components'
import { TabBar } from '@aragon/ui'
import BuyForm from './BuyForm'
import SellForm from './SellForm'


class TransferPanel extends React.Component {
  static defaultProps = {}

  state = { index: 0 }

  handleSubmit = event => {
    event.preventDefault()
  }

  handleSelect = index => {
    this.setState({ index })
  }

  render() {
    return (
      <TabBarWrapper>
        <TabBar
          items={['Buy', 'Sell']}
          selected={this.state.index}
          onSelect={this.handleSelect}
        />
        {this.state.index === 0 && (
          <BuyForm/>
        )}
        {this.state.index === 1 && (
          <SellForm/>
        )}
      </TabBarWrapper>
    )
  }
}

const TabBarWrapper = styled.div`
  margin: 0 -30px 30px;
`

export default TransferPanel
