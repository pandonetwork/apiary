import React from 'react'
import styled from 'styled-components'
import { TabBar, Field, Text, TextInput, Button } from '@aragon/ui'
import Aragon, { providers } from '@aragon/client'
import web3Utils from 'web3-utils'

const app = new Aragon(new providers.WindowMessage(window.parent))

const state_0 = { wei: 0, bonds: 0 }


class BuyForm extends React.Component {
  static defaultProps = {}

  state = { ...state_0 }

  handleSubmit = event => {
    event.preventDefault()
    app.buy(this.state.wei, { value: this.state.wei })
  }

  handleUpdate = event => {
    const value = web3Utils.toWei(event.target.value, 'ether')
    app.call('getBuy', value.toString()).subscribe(bonds => {
        console.log(bonds)
        this.setState({ wei: value, bonds: bonds })
      })
  }

  render() {
    return (
        <div>
          <FormWrapper>
            <form onSubmit={this.handleSubmit}>
              <Field label="ETH amount to buy bonds with">
                <TextInput.Number required wide step="any" onChange={this.handleUpdate}/>
              </Field>
              <Field label="Amount of bonds to be bought">
                <Text>{web3Utils.fromWei(this.state.bonds.toString(), 'ether')}</Text>
              </Field>
              <ButtonWrapper>
               <Button mode="strong" type="submit" wide>Buy</Button>
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
