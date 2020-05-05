using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using IoTReceiverAPI.Models;
using Microsoft.Extensions.Primitives;
using Microsoft.Azure.Devices.Client;

// For more information on enabling MVC for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace IoTReceiverAPI.Controllers
{

    [ApiController]
    [Route("[controller]")]
    public class MqttController : Controller
    {

        [HttpGet]
        [Route("{id}")]
        public string GetValues(string id)
        {
            return id;
        }

        // POST api/values
        [HttpPost]
        [Route("api")]
        public void Post([FromBody] MqttMessage mqttMessage)
        {

            StringValues connString;
            var mqttMessageString = JsonConvert.SerializeObject(mqttMessage);
            Request.Headers.TryGetValue("conn", out connString);
            Console.WriteLine(connString.ToString());
            Console.WriteLine(mqttMessageString);

            Task.Run(async () =>
            {

                var dc = DeviceClient.CreateFromConnectionString(connString, TransportType.Mqtt);
                var msg = new Message(Encoding.UTF8.GetBytes(mqttMessageString));
                await dc.SendEventAsync(msg);
                Console.WriteLine("Sent");

            });

        }

    }
}
