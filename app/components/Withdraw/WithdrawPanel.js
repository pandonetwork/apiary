import React from 'react'
import styled from 'styled-components'
import { TabBar, Field, TextInput, Button } from '@aragon/ui'
import Aragon, { providers } from '@aragon/client'


const app = new Aragon(new providers.WindowMessage(window.parent))


class WithdrawPanel extends React.Component {
  static defaultProps = {}

  handleSubmit = event => {
    event.preventDefault()
    app.withdraw()
  }

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <ButtonWrapper>
          <Button mode="strong" type="submit" wide>Withdraw</Button>
        </ButtonWrapper>
      </form>
    )
  }
}

const ButtonWrapper = styled.div`
  padding-top: 10px;
`
export default WithdrawPanel
