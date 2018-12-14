import React from 'react'
import styled from 'styled-components'
import { TabBar, Field, Text, TextInput, Button } from '@aragon/ui'
import Aragon, { providers } from '@aragon/client'
import web3Utils from 'web3-utils'

const app = new Aragon(new providers.WindowMessage(window.parent))


class BuyForm extends React.Component {
  static defaultProps = {}

  state = { wei: 0, bonds: 0 }

  handleSubmit = event => {
    event.preventDefault()
    app.sell(this.state.bonds)
  }

  handleUpdate = event => {
    const amount = web3Utils.toWei(event.target.value, 'ether')
    app.call('getSell', amount.toString()).subscribe(value => {
        this.setState({ wei: value, bonds: amount })
      })
  }

  render() {
    return (
        <div>
          <FormWrapper>
            <form onSubmit={this.handleSubmit}>
              <Field label="Amount of ABTs to sell">
                <TextInput.Number required wide step="any" onChange={this.handleUpdate}/>
              </Field>
              <Field label="ETH value">
                <Text>{web3Utils.fromWei(this.state.wei.toString(), 'ether')}</Text>
              </Field>
              <ButtonWrapper>
               <Button mode="strong" type="submit" wide>Sell</Button>
             </ButtonWrapper>

            </form>
          </FormWrapper>
        </div>
    )
  }
}

const FormWrapper = styled.div`
  padding: 30px;
`

const ButtonWrapper = styled.div`
  padding-top: 10px;
`


export default BuyForm
